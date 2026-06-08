class Pggraph < Formula
  desc "Graph database superpowers for your existing Postgres data"
  homepage "https://github.com/evokoa/pggraph"
  url "https://github.com/evokoa/pggraph/archive/refs/tags/v0.1.7.tar.gz"
  sha256 "f7e83ebfb4ac6d5be9a64950317bbca0cad8907148de6d5388430a3007c04f3e"
  license "Apache-2.0"

  depends_on "pgrx@0.18.1" => :build
  depends_on "postgresql@17" => [:build, :test]
  depends_on "rust" => :build

  def postgresql
    Formula["postgresql@17"]
  end

  def install
    pg_config = postgresql.opt_bin/"pg_config"
    pg_major = Utils.safe_popen_read(pg_config, "--version").match(/PostgreSQL (\d+)/)[1]
    package_dir = buildpath/"pggraph-package"

    cd "graph" do
      ENV["PGRX_HOME"] = buildpath/".pgrx"
      ENV.prepend_path "PATH", Formula["pgrx@0.18.1"].opt_bin

      system "cargo", "pgrx", "init", "--pg#{pg_major}", pg_config
      system "cargo", "pgrx", "package",
             "--pg-config", pg_config,
             "--out-dir", package_dir,
             "--no-default-features",
             "--features", "pg#{pg_major}"
    end

    staged_prefix = package_dir/HOMEBREW_PREFIX.to_s.delete_prefix("/")
    (lib/postgresql.name).install Dir[staged_prefix/"lib/#{postgresql.name}/*"]
    (share/postgresql.name/"extension").install Dir[staged_prefix/"share/#{postgresql.name}/extension/*"]
  end

  test do
    ENV["LC_ALL"] = "C"

    pg_ctl = postgresql.opt_bin/"pg_ctl"
    psql = postgresql.opt_bin/"psql"
    port = free_port
    datadir = testpath/postgresql.name

    system pg_ctl, "initdb", "-D", datadir
    (datadir/"postgresql.conf").write <<~EOS, mode: "a+"
      port = #{port}
      dynamic_library_path = '$libdir'
    EOS

    system pg_ctl, "start", "-D", datadir, "-l", testpath/"postgres.log"
    begin
      system psql, "-p", port.to_s, "-d", "postgres", "-c", "CREATE EXTENSION graph;"
      assert_match version.to_s,
                   Utils.safe_popen_read(psql, "-p", port.to_s, "-d", "postgres", "-Atc",
                                         "SELECT extversion FROM pg_extension WHERE extname = 'graph'")
    ensure
      system pg_ctl, "stop", "-D", datadir
    end
  end
end
