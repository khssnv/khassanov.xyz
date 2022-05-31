FROM ubuntu:latest as builder

# install hugo
ARG HUGO_VERSION="0.100.0"
ADD https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_Linux-64bit.tar.gz /tmp/
RUN tar -xf /tmp/hugo_${HUGO_VERSION}_Linux-64bit.tar.gz -C /usr/local/bin/

# install syntax highlighting
RUN apt-get update
RUN apt-get install -y hugo python3-pygments

# build site
COPY . /source
RUN hugo --source=/source/ --destination=/public/

FROM nginx:stable-alpine
RUN apk --update add bash
COPY --from=builder /public/ /usr/share/nginx/html/
EXPOSE 80
