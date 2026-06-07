class PgrxAT0181 < Formula
  desc "Build Postgres extensions with Rust"
  homepage "https://github.com/pgcentralfoundation/pgrx"
  url "https://github.com/pgcentralfoundation/pgrx/archive/refs/tags/v0.18.1.tar.gz"
  sha256 "a2a4ec1c90a17fe31a646cc2bd505992c28c375ba8a798d5cdeee27ca5d5ef0b"
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
