#!/usr/bin/env bash

main() {
  cd "$(dirname "$0")/"

    case "$1" in
      diff)
        cd code-server/lib
        diff -x node_modules -x build -x .build -x 'out-*' -x out -ru vscode.orig vscode
        ;;
      save-diff)
        cd code-server/lib
        diff -x node_modules -x build -x .build -x 'out-*' -x out -ru vscode.orig vscode > ../ci/dev/vscode.vh.patch
        ;;
      apply-patch)
        cd code-server/lib/vscode
        git apply ../../../vscode.vh.patch
        ;;
      build-android-env)
        docker build ./container/android -t vsandroidenv:latest
        ;;
      rebuild-server)
        cd code-server/lib/vscode
        CC_target=cc AR_target=ar CXX_target=cxx LINK_target=ld PATH=/vscode-build/bin:$PATH yarn
        ;;
      release)
        if [ ! -z "$BUILD_RELEASE" ]; then
          cd code-server
          date +'%Y%m%d%H%M' > VERSION
          rm -rf release release-static
          yarn release
          yarn release:static
          cd release-static
          CC_target=cc AR_target=ar CXX_target=cxx LINK_target=ld PATH=/vscode-build/bin:$PATH yarn --production --frozen-lockfile
          cd ../..
        fi
        rm -f cs.tar.gz
        tar -czvf cs.tar.gz code-server/VERSION code-server/release-static
        ;;
      *)
        docker run --rm -it \
                -w /vscode \
                -v $(pwd):/vscode \
                -v $(pwd)/container/android:/vscode-build \
                -v $(pwd)/node:/vscode-node \
                -v $(pwd)/.git/modules/code-server:/.git/modules/code-server \
                vsandroidenv:latest bash
        ;;
    esac
}

main "$@"

