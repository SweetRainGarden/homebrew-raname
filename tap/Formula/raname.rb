class Raname < Formula
  desc "A utility to rename files and directories, replacing text in both names and content"
  homepage "https://github.com/SweetRainGarden/homebrew-raname"
  url "https://github.com/SweetRainGarden/homebrew-raname/archive/refs/tags/v1.1.0.0.tar.gz"
  version "1.1.0.0"

  def install
    bin.install "bin/raname.sh" => "raname"
  end

  test do
    system "#{bin}/raname", "--version"
  end
end 