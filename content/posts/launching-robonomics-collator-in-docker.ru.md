---
title: "Запускаем коллатор Робономики в Докере"
date: 2022-01-09T20:43:22+03:00
draft: false
---

В [официальной инструкции](https://github.com/airalab/robonomics-wiki/blob/master/docs/en/collators-tips-and-tricks.md) по запуску коллатора предлагается собрать свой бинарный файл ноды Робономики или использовать опубликованный в последнем релизе.
Использование Docker образа не предлагается, т. к. последнее обновление на Docker Hub было полгода назад.
Это связано с проблемой сборки образа в CI, о которой уже сообщено в [Issue #232](https://github.com/airalab/robonomics/issues/232).
Однако довольно просто самостоятельно повторить [шаги которые делает CI](https://github.com/airalab/robonomics/blob/master/.github/workflows/release.yml#L8) чтобы сделать свой Docker образ.

tl;dr
-----

Вы можете использовать собранный мной образ Docker контейнера с нодой Робономики, тогда не нужно собирать его самостоятельно.
Нужно только сделать директорию для данных блокчейна и задать имя ноды и адрес для чаевых коллатора.

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

Самостоятельная сборка образа
-----------------------------

Установите Rust: [https://www.rust-lang.org/tools/install](https://www.rust-lang.org/tools/install).

Далее добавьте целевую архитектуру "wasm32-unknown-unknown" и тулчейн "nightly-2021-11-02".

```console
rustup target add wasm32-unknown-unknown
rustup toolchain install nightly-2021-11-02
```

Скопируйте исходный код последней версии ноды Робономики.

```console
git clone -b v1.4.0 https://github.com/airalab/robonomics.git
```

Запустите сборку.
Она может занять довольно много времени.

```console
cd robonomics
cargo build -j 4 --locked --release
```

Теперь можно собрать образ контейнера для Docker, благо Dockerfile уже написан разработчиками.

```console
cd scripts/docker # переходим в директорию с Dockerfile
cp ../../target/release/robonomics . # копируем собранный бинарный файл ноды
docker build -f ./Dockerfile --build-arg RUSTC_WRAPPER= --build-arg PROFILE=release -t myrobonomics/robonomics:v1.4.0 .
```

Готово!
Теперь можно запустить ноду в докер-контейнере.
Нужно только подготовить директорию для данных блокчейна и задать имя ноды и адрес коллатора на который будут поступать чаевые коллатора.

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

Если Вы хотите ускорить синхронизацию, в директорию `data` можно положить распакованный снапшот релейчейна.
Подробнее об этом в конце [официальной инструкции](https://github.com/airalab/robonomics-wiki/blob/master/docs/en/how-to-launch-the-robonomics-collator.md#using-kusama-snapshot-for-making-syncronization-faster).
Только в нашем случае распаковать архив нужно будет не в `/home/robonomics/.local/share/robonomics/polkadot/chains/ksmcc3`, а в `data/polkadot/chains/ksmcc3`.
