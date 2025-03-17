class Rename < Formula
  desc "Recursively rename files, directories, and replace content"
  homepage "https://github.com/SweetRainGarden/BrewRename"
  url "https://github.com/SweetRainGarden/BrewRename/archive/refs/tags/1.0.0.0.zip"
  sha256 "a2777bddd0a986345bc74de4c018606da38fab56"
  version "1.0"
  license "MIT"

  def install
    bin.install "bin/rename"
  end

  test do
    system "#{bin}/rename", "--help"
  end
end
