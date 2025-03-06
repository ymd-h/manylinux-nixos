FROM nixos/nix:2.26.3
WORKDIR /work
COPY . /manylinux
RUN nix --experimental-features "nix-command flakes" develop -L /manylinux#test
CMD ["nix", "--experimental-features", "nix-command flakes", "develop", "-L", "/manylinux#test"]

