
### Installing koinos-tools

We'll be using the `koinos-tools` repository [here](https://github.com/koinos/koinos-tools).
(The tools in the `koinos-tools` repository are very rough and developer-oriented.  You have
to do a lot of things manually, which should help improve understanding of how Koinos works.)

The simplest way to interact with `koinos-tools` is via the Docker image
which can be found [here on Dockerhub](https://hub.docker.com/r/koinos/koinos-tools).
You can install the Docker image from Dockerhub like this:

```
docker pull koinos/koinos-tools
```

Or you can build the Docker container from source like this:

```
git clone https://github.com/koinos/koinos-tools
cd koinos-tools
docker build . -t koinos/koinos-tools:latest
```

Once you have the Docker container, you can get a shell inside it.  Containers are temporary,
but we want our private keys to be permanently stored so they're available after the container
is shut down.  We will store our private keys in the `mykeys` directory, and make the directory
available in the container with the `-v` option of `docker run`:

```
mkdir -p mykeys
docker run -it -v $(pwd)/mykeys:/mykeys koinos/koinos-tools /bin/sh
```

If you don't want to run the tools inside a Docker container, you can instead build and
install the tool binaries natively by building the `koinos-tools` repository from source.
The repository is located [here on Github](https://github.com/koinos/koinos-tools).

### Generating keys

We can generate a keypair like this:

```
koinos_get_dev_key -s myseedphrase -o /mykeys/my.key
```

The seed phrase is used to deterministically generate a keypair for development.
If you want a slightly more secure key, you can omit the seed phrase to randomly generate a key.

The address is printed to stdout:

```
Generated key: 18fMfixQE4DHKMSX2ybupikp8wfpYqtc9Y
```

The private key is stored in my.key in WIF format:

```
$ cat mykeys/my.key
5KPvyDLLg94Vr3XPym8xEYkqgCoA6yCzvq7xvHx5sQg8CEHZUgY
```

Anyone with access to the private key can send funds from your account.  So back up your private key,
don't share it with anyone, and definitely don't post it in online chats / forums / websites etc.
(If you're not familiar with private keys, you may want to look up best practices for private key
security.)

### Getting test KOIN

To get some tKOIN (testnet coins) at your address, you can ask the Discord bot.  In discord type:

```
!faucet 18fMfixQE4DHKMSX2ybupikp8wfpYqtc9Y
```

Now let's create another key for Bob:

```
koinos_get_dev_key -s bobseedphrase -o /mykeys/bob.key
```

To transact with an address, you have to input a transaction nonce.  (The nonce is a number equal to the total
number of transactions executed by the address, including the current transaction.  The nonce serves as
a replay prevention mechanism.  Ethereum also uses this mechanism for replay prevention.)

To find the transaction nonce, you need a running node.  For the purposes of this example, I'll assume
the node is running on `localhost`.  You can encode the key as follows:

```
ADDRESS="18fMfixQE4DHKMSX2ybupikp8wfpYqtc9Y"
B64_ADDRESS=$(echo -n "$ADDRESS" | base64)
curl -X POST \
     -H 'Content-Type: application/json' \
     -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"chain.get_account_nonce\",\"params\":{\"account\" : \"M$B64_ADDRESS\"}}" \
     http://localhost:8080
```

Koinos uses [multibase encoding](https://github.com/multiformats/multibase) in many places throughout the blockchain API.  A large
number of prefixes are defined for multibase, but Koinos currently supports only a limited subset of the defined prefixes.
The most common prefixes are `M` (for the `base64pad` encoding) and `z` (for the `base58` encoding).

The available `chain.` methods, their parameters and return types are defined in
[chain_rpc.hpp](https://github.com/koinos/koinos-types/blob/master/types/chain_rpc.hpp)
in the `koinos-types` repo.

### Calling a smart contract

In Koinos, the core token (tKOIN) is defined by a smart contract.  The JSON-RPC tooling is unaware of the internals
of a smart contract, so we'll need to serialize requests and responses for a smart contract ourselves.  The process for
this is currently quite rough, and will perhaps soon be replaced by [Cap'n Proto](https://capnproto.org/).

The smart contract objects are specified in each smart contract, for example the tKOIN smart contract is
[here](https://github.com/koinos/koinos-system-contracts/blob/master/contracts/koin/koin.cpp).  These definitions are duplicated
in the serializer tools.

To call a smart contract, we need to know the two things:

- The address of the smart contract
- The code for the entry point of the method we want to call (i.e. `symbol()`)

Smart contract ID's are currently 160 bits.  The smart contract ID of the tKOIN smart contract is `z33qAMjTLGff2wD57oM6HbHoKSg2P`.
The `symbol()` entry point is defined [in koin.cpp](https://github.com/koinos/koinos-system-contracts/blob/master/contracts/koin/koin.cpp)
to be `0x7e794b24`.  JSON does not support hex values, so we convert this to decimal and obtain `2121878308`.

We can call `symbol()` like this:

```
curl -X POST \
     -H 'Content-Type: application/json' \
     -d "{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"chain.read_contract\",\"params\":{\"contract_id\":\"z33qAMjTLGff2wD57oM6HbHoKSg2P\", \"entry_point\":2121878308}}" \
     http://localhost:8080
```

If everything is working properly, we should get a JSON response like this:

```
$ curl ...
{"jsonrpc":"2.0","result":{"logs":"","result":"MBXRLT0lO"},"id":2}
```

To decode this return value, we can strip off the leading `M` (which is the multibase specifier for the
`base64pad` encoding), decode the rest of the string using the standard `base64` command-line tool, and
finally get a hex dump of the returned bytes using `hd`:

```
$ echo BXRLT0lO | base64 -d | hd
00000000  05 74 4b 4f 49 4e                                 |.tKOIN|
00000006
```

The result is the 5-character long string `tKOIN`.

### Calling smart contract with arguments

In the previous section, we called the `symbol()` function, which takes no arguments.  In order to call a smart
contract entry point that takes arguments, we need to specify the encoded arguments in the `args` parameter to
`chain.read_contract` (we omitted this parameter entirely in the previous example).

This means we need to encode the arguments.  This can be done with the `koinos_obj_serializer` program in
`koinos-tools`, which makes the Koinos type system's encoding / decoding functionality available to other
programs.  (Eventually the entire type system architecture may be replaced by Cap'n Proto.)

If we have a Bitcoin-style address such as `1Krs7v1rtpgRyfwEZncuKMQQnY5JhqXVSx` we will need to serialize it
as a string of bytes.  (This particular address is the testnet genesis address and is likely to have an
interesting balance.  If you got tokens from the faucet, you can check the balance of your own address.)
We then pass into `koinos_obj_serializer` and finally to Curl.  The entire process looks like this:

```
$ echo -n "1Krs7v1rtpgRyfwEZncuKMQQnY5JhqXVSx" | base64
MUtyczd2MXJ0cGdSeWZ3RVpuY3VLTVFRblk1SmhxWFZTeA==
$ echo '{"type" : "koinos::koin::balance_of_args", "value" : {"owner" : "MMUtyczd2MXJ0cGdSeWZ3RVpuY3VLTVFRblk1SmhxWFZTeA=="}}' | programs/koinos_object_serializer/koinos_obj_serializer
MIjFLcnM3djFydHBnUnlmd0VabmN1S01RUW5ZNUpocVhWU3g=
$ curl -X POST \
       -H 'Content-Type: application/json' \
       -d "{\"jsonrpc\":\"2.0\",\"id\":3,\"method\":\"chain.read_contract\",\"params\":{\"contract_id\":\"z33qAMjTLGff2wD57oM6HbHoKSg2P\", \"entry_point\":358715976, \"args\":\"MIjFLcnM3djFydHBnUnlmd0VabmN1S01RUW5ZNUpocVhWU3g=\"}}" \
       http://localhost:8080
{"jsonrpc":"2.0","result":{"logs":"","result":"MAAKPUUcELAA="},"id":3}
$ echo '{"type" : "koinos::koin::balance_of_result", "bytes" : "MAAKPUUcELAA="}' | programs/koinos_object_serializer/koinos_obj_serializer -d
{"type":"koinos::koin::balance_of_result","value":{"balance":720529200000000}}
```

A couple notes:

- Since we're using `base64pad` encoding, we prepend `M` as the multibase specifier for the `"owner"` string
- This double encoding is [considered a bug](https://github.com/koinos/koinos-chain/issues/450) and will likely
not be required in some future version of Koinos.
- Getting the number of decimal places by calling `decimals()`
