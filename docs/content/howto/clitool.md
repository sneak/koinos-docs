
### Installing koinos-tools

We'll be using the `koinos-tools` repository [here](https://github.com/koinos/koinos-tools).
(The tools in the `koinos-tools` repository are very rough and developer-oriented.  They are
intended to allow developers to interact with the chain today.  End-users should have a
wallet that gives a much smoother experience.  But as of early July 2021, a Koinos wallet
has not yet been implemented.)

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

The available `chain.` methods, their parameters and return types are defined in
[chain_rpc.hpp](https://github.com/koinos/koinos-types/blob/master/types/chain_rpc.hpp)
in the `koinos-types` repo.

Getting the tKOIN balance of an address involves interacting with a smart contract.  That's because in Koinos, the core token
(tKOIN) is defined by a smart contract.  The JSON-RPC tooling is unaware of the internals of a smart contract, so we'll
need to serialize requests and responses for a smart contract ourselves.  The process for this is currently quite rough,
and will perhaps soon be replaced by [Cap'n Proto](https://capnproto.org/).

The smart contract objects are specified in each smart contract, for example the tKOIN smart contract is
[here](https://github.com/koinos/koinos-system-contracts/blob/master/contracts/koin/koin.cpp).  These definitions are duplicated
in the serializer tools.

To check the contract, we need to execute the `name()` entry point.  The code for this entry point is `0x76ea4297`, as defined
in `enum entries` near the top of `koin.cpp`.

```
{"type" : "koinos::koin::transfer_args", "value" : {"from" : "z1Krs7v1rtpgRyfwEZncuKMQQnY5JhqXVSx", "to" : "z1Krs7v1rtpgRyfwEZncuKMQQnY5JhqXVSx", "value" : 1000} }
```

For this to work, we'll need to export a definition of the smart contract's objects, which currently exists only in the
smart contract's source code.

The definition of the `koin` contract 

To get the balance of the address, we can use the following transaction:

```
curl -X POST \
     -H 'Content-Type: application/json' \
     -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"chain.get_account_nonce\",\"params\":{\"account\" : \"M$B64_ADDRESS\"}}" \
     http://localhost:8080
```

    transaction = {'id': 'z11', 'active_data': {'resource_limit': app.config["resource_limit"],
    'nonce': app.chain.get_nonce(), 'operations': [{'type': 'koinos::protocol::call_contract_operation',
    'value': {'contract_id': app.config["contract_id"], 'entry_point': app.config["transfer_entry_point"], 'args': args, 'extensions': {}}}]},
    'passive_data': {}, 'signature_data': 'z11'}

{"type" : "koinos::koin::transfer_args", "value" : {"from" : "z1Krs7v1rtpgRyfwEZncuKMQQnY5JhqXVSx", "to" : "z1Krs7v1rtpgRyfwEZncuKMQQnY5JhqXVSx", "value" : 1000} }


ADDRESS="1Krs7v1rtpgRyfwEZncuKMQQnY5JhqXVSx"
B64_ADDRESS=$(echo -n "$ADDRESS" | base64)
curl -X POST \
     -H 'Content-Type: application/json' \
     -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"chain.get_account_nonce\",\"params\":{\"account\" : \"M$B64_ADDRESS\"}}" \
     http://localhost:8080
