class PgrxAT0180 < Formula
  desc "Build Postgres extensions with Rust"
  homepage "https://github.com/pgcentralfoundation/pgrx"
  url "https://github.com/pgcentralfoundation/pgrx/archive/refs/tags/v0.18.0.tar.gz"
  sha256 "fc39703527b34f916fef9fb0e44e8aab3f5691e1f15f7e89030d96050c322afe"
  license "MIT"

  keg_only :versioned_formula

  depends_on "pkgconf" => :build
  depends_on "rust" => :build
  depends_on "openssl@3"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "cargo", "install", *std_cargo_args(path: "cargo-pgrx")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/cargo-pgrx --version")
  end
end
