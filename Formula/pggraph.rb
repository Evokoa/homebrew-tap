class Pggraph < Formula
  desc "Graph database superpowers for your existing Postgres data"
  homepage "https://github.com/evokoa/pggraph"
  url "https://github.com/evokoa/pggraph/archive/refs/tags/v0.1.6.tar.gz"
  sha256 "4b53dbebf866490a5dee732bebd9f06512b5dba9b395127b830463238357cb6e"
  license "Apache-2.0"

  depends_on "pgrx@0.18.1" => :build
  depends_on "rust" => :build
  depends_on "postgresql@17" => [:build, :test]

  def postgresql
    Formula["postgresql@17"]
  end

  def install
    pg_config = postgresql.opt_bin/"pg_config"
    pg_major = shell_output("#{pg_config} --version").match(/PostgreSQL (\d+)/)[1]
    package_dir = buildpath/"pggraph-package"

    cd "graph" do
      system Formula["pgrx@0.18.1"].opt_bin/"cargo-pgrx", "package",
             "--pg-config", pg_config,
             "--out-dir", package_dir,
             "--no-default-features",
             "--features", "pg#{pg_major}"
    end

    staged_prefix = package_dir/HOMEBREW_PREFIX.to_s.delete_prefix("/")
    lib.install Dir[staged_prefix/"lib/#{postgresql.name}/*"]
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
                   shell_output("#{psql} -p #{port} -d postgres -Atc \"SELECT extversion FROM pg_extension WHERE extname = 'graph'\"")
    ensure
      system pg_ctl, "stop", "-D", datadir
    end
  end
end
