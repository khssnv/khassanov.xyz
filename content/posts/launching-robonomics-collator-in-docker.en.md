---
title: "Launching Robonomics collator in Docker"
date: 2022-01-09T20:43:22+03:00
draft: false
---

In the [official guide](https://github.com/airalab/robonomics-wiki/blob/master/docs/en/collators-tips-and-tricks.md) on collator setup it is proposed to build your own Robonomics node binary or use one from the latest release published.
Docker is not proposed while the latest version at Docker Hub was a half year ago.
The reason is a build issue in CI pipeline, it is already reported in [Issue #232](https://github.com/airalab/robonomics/issues/232).
However it is pretty easy to repeat [the same steps CI does](https://github.com/airalab/robonomics/blob/master/.github/workflows/release.yml#L8) to build your own Docker image.

tl;dr
-----

You can use a Docker image built my me, this way you are free from building Robonomics node and an image with it by your own.
Create a directory for blockchain database, setup node name and collator address (for tips) and you are ready to launch it.

```console
mkdir data
export NODE_NAME="NewNode"
export ACCOUNT_ADDRESS="YourAccountAddress"
docker run -d \
  --name "robonomics" \
  -v $(pwd)/data:/data \
  khassanov/robonomics:v1.4.0 /usr/local/bin/robonomics \
  --parachain-id=2048 \
  --name="$NODE_NAME" \
  --validator \
  --lighthouse-account="$ACCOUNT_ADDRESS" \
  --telemetry-url="wss://telemetry.parachain.robonomics.network/submit/ 0" \
  -- \
  --database=RocksDb \
  --unsafe-pruning \
  --pruning=1000
```

Building your own image
-----------------------

Install Rust: [https://www.rust-lang.org/tools/install](https://www.rust-lang.org/tools/install).

Add "wasm32-unknown-unknown" target architecture and "nightly-2021-11-02" toolchain.

```console
rustup target add wasm32-unknown-unknown
rustup toolchain install nightly-2021-11-02
```

Copy Robonomics node latest stable version source code.

```console
git clone -b v1.4.0 https://github.com/airalab/robonomics.git
```

Run build process.
It may take a while.

```console
cd robonomics
cargo build -j 4 --locked --release
```

Now we can build Docker image.
Fortunately, Robonomics developers made a Dockerfile.

```console
cd scripts/docker # go to a dir with Dockerfile
cp ../../target/release/robonomics . # copy node binary file
docker build -f ./Dockerfile --build-arg RUSTC_WRAPPER= --build-arg PROFILE=release -t myrobonomics/robonomics:v1.4.0 .
```

That's it!
Now we can launch Robonomics node in Docker container.
Create a directory for blockchain database, setup node name and collator address (for tips) and run a container.

```console
mkdir data
export NODE_NAME="NewNode"
export ACCOUNT_ADDRESS="YourAccountAddress"
docker run -d \
  --name "robonomics" \
  -v $(pwd)/data:/data \
  myrobonomics/robonomics:v1.4.0 /usr/local/bin/robonomics \
  --parachain-id=2048 \
  --name="$NODE_NAME" \
  --validator \
  --lighthouse-account="$ACCOUNT_ADDRESS" \
  --telemetry-url="wss://telemetry.parachain.robonomics.network/submit/ 0" \
  -- \
  --database=RocksDb \
  --unsafe-pruning \
  --pruning=1000
```

If you want to speed up synchronozation, you can put relaychain snapshot into `data` directory.
You can find more details on it in the [official guide](https://github.com/airalab/robonomics-wiki/blob/master/docs/en/how-to-launch-the-robonomics-collator.md#using-kusama-snapshot-for-making-syncronization-faster).
The only difference is that in our case we should unpack the archive in `data/polkadot/chains/ksmcc3` directory instead of `/home/robonomics/.local/share/robonomics/polkadot/chains/ksmcc3` given in the guide.
