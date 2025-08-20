class Notify < Formula
  desc "Send macOS User Notifications from the command line"
  homepage "https://github.com/yourusername/notify"
  version "2.0.0"
  
  on_arm do
    url "https://github.com/yourusername/notify/releases/download/v2.0.0/notify-2.0.0-darwin.tar.gz"
    sha256 "PUT_ARM64_SHA256_HERE"
  end
  
  on_intel do  
    url "https://github.com/yourusername/notify/releases/download/v2.0.0/notify-2.0.0-darwin.tar.gz"
    sha256 "PUT_X86_64_SHA256_HERE"
  end

  depends_on macos: :ventura
  conflicts_with "terminal-notifier", because: "both provide notification functionality"

  def install
    prefix.install "notify.app"
    bin.install_symlink "#{prefix}/notify.app/Contents/MacOS/notify"
  end

  def caveats
    <<~EOS
      notify requires macOS 13.0 (Ventura) or later.
      
      The application bundle is installed to:
        #{prefix}/notify.app
      
      The command-line tool is symlinked to:
        #{bin}/notify
        
      Note: This formula conflicts with the legacy terminal-notifier formula.
      If you have the old version installed, run:
        brew uninstall terminal-notifier
    EOS
  end

  test do
    system "#{bin}/notify", "--help"
    assert_match version.to_s, shell_output("#{bin}/notify --version")
  end
end