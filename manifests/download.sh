#!/bin/bash

download_release()
{
  local release="$1"
  local tag_name=$(echo "$release" | jq -r '.tag_name')
  local url=$(echo "$release" | jq -r '.assets[]|select(.name=="install.yaml")|.browser_download_url')

  if [ -z "$tag_name" ] || [ -z "$url" ]; then
    echo Failed gettting latest release
    exit 1
  fi

  echo Downloading release $tag_name from $url
  curl -s -L -o install-${tag_name}.yaml $url
}

if [ $# -eq 0 ]; then
  release=$(curl -s https://api.github.com/repos/fluxcd/flux2/releases/latest)
  download_release "$release"
  tag_name=$(echo "$release" | jq -r '.tag_name')
  ln -fs install-${tag_name}.yaml install-latest.yaml
else
  for tag_name; do
    release=$(curl -s https://api.github.com/repos/fluxcd/flux2/releases/tags/$tag_name)
    download_release "$release"
  done
fi
