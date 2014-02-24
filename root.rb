require 'formula'

class Root < Formula
  homepage 'http://root.cern.ch'
  url 'ftp://root.cern.ch/root/root_v5.34.17.source.tar.gz'
  version '5.34.17'
  sha1 '57c8f70fe4f72d1a9b8aea2044fece8756b8c977'
  head 'https://github.com/root-mirror/root.git', :branch => 'v5-34-00-patches'

  option 'with-x11', "Use X11 for graphics backend instead of Cocoa"
  depends_on 'xrootd' => :recommended
  depends_on 'fftw' => :optional
  depends_on :x11
  depends_on :python

  def patches
    # http://trac.macports.org/ticket/36777
    { :p0 => "http://trac.macports.org/raw-attachment/ticket/36777/patch-builtin-afterimage-disabletiff.diff" } if build.without? 'x11'
  end

  def install
    # brew audit doesn't like non-executables in bin
    # so we will move {thisroot,setxrd}.{c,}sh to libexec
    # (and change any references to them)
    inreplace Dir['config/roots.in', 'config/thisroot.*sh',
                  'etc/proof/utils/pq2/setup-pq2',
                  'man/man1/setup-pq2.1', 'README/INSTALL', 'README/README'],
      /bin.thisroot/, 'libexec/thisroot'

    # Determine architecture
    arch = MacOS.prefer_64_bit? ? 'macosx64' : 'macosx'
    cocoa_flag = (build.with? 'x11') ? "--disable-cocoa" : "--enable-cocoa"

    # N.B. that it is absolutely essential to specify
    # the --etcdir flag to the configure script.  This is
    # due to a long-known issue with ROOT where it will
    # not display any graphical components if the directory
    # is not specified:
    # http://root.cern.ch/phpBB3/viewtopic.php?f=3&t=15072
    system "./configure",
           "#{arch}",
           "--all",
           "--enable-builtin-glew",
           "#{cocoa_flag}",
           "--prefix=#{prefix}",
           "--etcdir=#{prefix}/etc/root",
           "--mandir=#{man}"
    system "make"
    system "make install"

    # needed to run test suite
    prefix.install 'test'

    libexec.mkpath
    mv Dir["#{bin}/*.*sh"], libexec
  end

  def test
    system "make -C #{prefix}/test/ hsimple"
    system "#{prefix}/test/hsimple"
  end

  def caveats; <<-EOS.undent
    Because ROOT depends on several installation-dependent
    environment variables to function properly, you should
    add the following commands to your shell initialization
    script (.bashrc/.profile/etc.), or call them directly
    before using ROOT.

    For csh/tcsh users:
      source `brew --prefix root`/libexec/thisroot.csh
    For bash/zsh users:
      . $(brew --prefix root)/libexec/thisroot.sh
    EOS
  end
end
