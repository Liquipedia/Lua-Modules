# Same image CI uses for visual snapshot tests (see ".github/workflows/update
# visual snapshots.yml"), so snapshots rendered in here match the ones CI
# commits back to the branch. Keep the tag in sync with the playwright version
# in package.json.
FROM mcr.microsoft.com/playwright:v1.61.1-noble

# Keep these in sync with the versions used by the GitHub workflows
ARG LUA_VERSION=5.1.5
ARG LUAROCKS_VERSION=3.11.1
ARG LUALS_VERSION=3.18.2
ARG RUFF_VERSION=0.15.22

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		build-essential \
		ca-certificates \
		curl \
		libreadline-dev \
		python3 \
		python3-venv \
		unzip \
	&& rm -rf /var/lib/apt/lists/*

# Lua 5.1, built from source the same way Liquipedia/gh-actions-lua does in CI.
# Anything newer than 5.1 is unsupported, see the README.
RUN curl -fsSL "https://www.lua.org/ftp/lua-${LUA_VERSION}.tar.gz" -o /tmp/lua.tar.gz \
	&& tar -xzf /tmp/lua.tar.gz -C /tmp \
	&& make -C "/tmp/lua-${LUA_VERSION}" linux MYCFLAGS="-O2 -fPIC" \
	&& make -C "/tmp/lua-${LUA_VERSION}" install \
	&& rm -rf /tmp/lua.tar.gz "/tmp/lua-${LUA_VERSION}"

RUN curl -fsSL "https://luarocks.org/releases/luarocks-${LUAROCKS_VERSION}.tar.gz" -o /tmp/luarocks.tar.gz \
	&& tar -xzf /tmp/luarocks.tar.gz -C /tmp \
	&& cd "/tmp/luarocks-${LUAROCKS_VERSION}" \
	&& ./configure --lua-version=5.1 --with-lua=/usr/local \
	&& make \
	&& make install \
	&& rm -rf /tmp/luarocks.tar.gz "/tmp/luarocks-${LUAROCKS_VERSION}"

# busted = test framework, luacheck = linter
RUN luarocks install --lua-version=5.1 busted \
	&& luarocks install --lua-version=5.1 luacheck

# lua-language-server, used by the "luals-code-style" CI job and by the Lua
# editor extension
RUN arch="$(dpkg --print-architecture)" \
	&& case "${arch}" in \
		amd64) luals_arch=x64 ;; \
		arm64) luals_arch=arm64 ;; \
		*) echo "unsupported architecture: ${arch}" >&2; exit 1 ;; \
	esac \
	&& mkdir -p /opt/luals \
	&& curl -fsSL "https://github.com/LuaLS/lua-language-server/releases/download/${LUALS_VERSION}/lua-language-server-${LUALS_VERSION}-linux-${luals_arch}.tar.gz" \
		| tar -xz -C /opt/luals \
	&& ln -s /opt/luals/bin/lua-language-server /usr/local/bin/lua-language-server

# Python lives in a venv so it is writable without fighting PEP 668. The
# scripts/ requirements themselves are installed by post-create.sh, so that
# changing requirements.txt does not need an image rebuild.
ENV VIRTUAL_ENV=/opt/venv
ENV PATH=/opt/venv/bin:${PATH}
RUN python3 -m venv "${VIRTUAL_ENV}" \
	&& pip install --no-cache-dir --upgrade pip \
	&& pip install --no-cache-dir "ruff==${RUFF_VERSION}" \
	&& chmod -R a+rwX "${VIRTUAL_ENV}"
