class Rename < Formula
  desc "Recursively rename files, directories, and replace content"
  homepage "https://github.com/SweetRainGarden/BrewRename"
  url "https://github.com/SweetRainGarden/BrewRename/archive/refs/tags/v1.0.tar.gz"
  sha256 "YOUR_TARBALL_SHA256_HASH"
  version "1.0"
  license "MIT"

  def install
    bin.install "bin/rename"
  end

  test do
    system "#{bin}/rename", "--help"
  end
end
