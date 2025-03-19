class Rename < Formula
  desc "A utility to rename files and directories, replacing text in both names and content"
  homepage "https://github.com/SweetRainGarden/homebrew-rename"
  url "https://github.com/SweetRainGarden/homebrew-rename/archive/refs/tags/v1.1.0.0.tar.gz"
  version "1.1.0.0"

  def install
    bin.install "bin/rename.sh" => "rename"
  end

  test do
    system "#{bin}/rename", "--version"
  end
end 