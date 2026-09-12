{
  description = "zenn-contents — Zenn に投稿するコンテンツと、その執筆環境";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system:
        f {
          inherit system;
          pkgs = nixpkgs.legacyPackages.${system};
        });
    in
    {
      devShells = forAllSystems ({ pkgs, ... }: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            # JS 側 (zenn-cli / textlint とそのルール) は pnpm-lock.yaml が固定する。
            # nix はその実行環境だけを固定する。
            nodejs_24
            pnpm

            # 単体で閉じるので nixpkgs から直接もらうツール
            markdownlint-cli2 # Markdown の構文・スタイル
            typos # タイポ検出
            lychee # リンク切れチェック
          ];

          shellHook = ''
            # pnpm 管理のツール (zenn / textlint) に PATH を通す
            export PATH="$PWD/node_modules/.bin:$PATH"

            if [ ! -d node_modules ]; then
              echo "node_modules がありません。pnpm install を実行します..."
              pnpm install --frozen-lockfile
            fi

            echo "zenn-contents: zenn preview / pnpm lint:text / markdownlint-cli2 / typos / lychee ."
          '';
        };
      });

      formatter = forAllSystems ({ pkgs, ... }: pkgs.nixpkgs-fmt);
    };
}
