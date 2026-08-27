# Backward-compatibility aliases for the xorg package scope.
# All packages have been moved to the top level as standalone packages.
#
# This file provides legacy attribute names (camelCase and compressed names)
# that map to the new top-level hyphenated package names.
{
  lib,
}:

self: {

  # Fonts (legacy camelCase → hyphenated top-level)
  encodings = self."font-encodings" or null;
  fontadobe100dpi = self."font-adobe-100dpi" or null;
  fontadobe75dpi = self."font-adobe-75dpi" or null;
  fontadobeutopia100dpi = self."font-adobe-utopia-100dpi" or null;
  fontadobeutopia75dpi = self."font-adobe-utopia-75dpi" or null;
  fontadobeutopiatype1 = self."font-adobe-utopia-type1" or null;
  fontalias = self."font-alias" or null;
  fontarabicmisc = self."font-arabic-misc" or null;
  fontbh100dpi = self."font-bh-100dpi" or null;
  fontbh75dpi = self."font-bh-75dpi" or null;
  fontbhlucidatypewriter100dpi = self."font-bh-lucidatypewriter-100dpi" or null;
  fontbhlucidatypewriter75dpi = self."font-bh-lucidatypewriter-75dpi" or null;
  fontbhttf = self."font-bh-ttf" or null;
  fontbhtype1 = self."font-bh-type1" or null;
  fontbitstream100dpi = self."font-bitstream-100dpi" or null;
  fontbitstream75dpi = self."font-bitstream-75dpi" or null;
  fontbitstreamtype1 = self."font-bitstream-type1" or null;
  fontcronyxcyrillic = self."font-cronyx-cyrillic" or null;
  fontcursormisc = self."font-cursor-misc" or null;
  fontdaewoomisc = self."font-daewoo-misc" or null;
  fontdecmisc = self."font-dec-misc" or null;
  fontibmtype1 = self."font-ibm-type1" or null;
  fontisasmisc = self."font-isas-misc" or null;
  fontjismisc = self."font-jis-misc" or null;
  fontmicromisc = self."font-micro-misc" or null;
  fontmisccyrillic = self."font-misc-cyrillic" or null;
  fontmiscethiopic = self."font-misc-ethiopic" or null;
  fontmiscmeltho = self."font-misc-meltho" or null;
  fontmiscmisc = self."font-misc-misc" or null;
  fontmuttmisc = self."font-mutt-misc" or null;
  fontschumachermisc = self."font-schumacher-misc" or null;
  fontscreencyrillic = self."font-screen-cyrillic" or null;
  fontsonymisc = self."font-sony-misc" or null;
  fontsunmisc = self."font-sun-misc" or null;
  fontutil = self."font-util" or null;
  fontwinitzkicyrillic = self."font-winitzki-cyrillic" or null;
  fontxfree86type1 = self."font-xfree86-type1" or null;

  # Libraries (legacy CamelCase → lowercase top-level)
  libAppleWM = self.libapplewm or null;
  libFS = self.libfs or null;
  libICE = self.libice;
  libpthreadstubs = self."libpthread-stubs";
  libSM = self.libsm;
  libWindowsWM = self.libwindowswm or null;
  libX11 = self.libx11;
  libXau = self.libxau;
  libXaw = self.libxaw;
  libXcomposite = self.libxcomposite or null;
  libXcursor = self.libxcursor or null;
  libXdamage = self.libxdamage or null;
  libXdmcp = self.libxdmcp;
  libXext = self.libxext;
  libXfixes = self.libxfixes;
  libXfont2 = self.libxfont2 or null;
  libXfont = self.libxfont1 or null;
  libXi = self.libxi;
  libXinerama = self.libxinerama or null;
  libXmu = self.libxmu;
  libXp = self.libxp or null;
  libXpm = self.libxpm;
  libXpresent = self.libxpresent or null;
  libXrandr = self.libxrandr;
  libXrender = self.libxrender;
  libXres = self.libxres or null;
  libXScrnSaver = self.libxscrnsaver or null;
  libXt = self.libxt;
  libXtst = self.libxtst or null;
  libXv = self.libxv or null;
  libXvMC = self.libxvmc or null;
  libXxf86dga = self.libxxf86dga or null;
  libXxf86misc = self.libxxf86misc or null;
  libXxf86vm = self.libxxf86vm;

  # Utilities and other packages
  twm = self."tab-window-manager" or null;
  utilmacros = self."util-macros" or null;
  xcbproto = self."xcb-proto";
  xcbutilcursor = self."libxcb-cursor" or null;
  xcbutilerrors = self.xcbutilerrors;
  xcbutilimage = self.xcbutilimage;
  xcbutilkeysyms = self.xcbutilkeysyms;
  xcbutil = self.xcbutil;
  xcbutilrenderutil = self.xcbutilrenderutil;
  xcbutilwm = self.xcbutilwm;
  xkeyboardconfig = self."xkeyboard-config";
  xcursorthemes = self."xcursor-themes" or null;
  xorgcffiles = self."xorg-cf-files" or null;
  xorgdocs = self."xorg-docs" or null;
  xorgsgmldoctools = self."xorg-sgml-doctools" or null;

  # Packages that were in the generated callPackage set, now top-level
  inherit (self)
    xorgproto
    libpciaccess
    libxshmfence
    libx11
    ;
  xorgserver = self."xorg-server";
  inherit (self)
    xclock
    xdm
    xdpyinfo
    xfd
    xfs
    xinit
    xinput
    xkbcomp
    xkbevd
    xkbprint
    xload
    xpr
    xrdb
    xwd
    ;
  inherit (self) libxtrap;
  libXTrap = self.libxtrap;
  inherit (self) xtrap xvfb;
  mkfontdir = self.mkfontscale;
  inherit (self) wrapWithXFileSearchPathHook;

  # xf86 driver aliases (camelCase → hyphenated top-level)
  xf86inputevdev = self."xf86-input-evdev";
  xf86inputjoystick = self."xf86-input-joystick";
  xf86inputkeyboard = self."xf86-input-keyboard" or null;
  xf86inputlibinput = self."xf86-input-libinput";
  xf86inputmouse = self."xf86-input-mouse" or null;
  xf86inputsynaptics = self."xf86-input-synaptics";
  xf86inputvmmouse = self."xf86-input-vmmouse";
  xf86inputvoid = self."xf86-input-void";
  xf86videoamdgpu = self."xf86-video-amdgpu";
  xf86videoapm = self."xf86-video-apm";
  xf86videoark = self."xf86-video-ark";
  xf86videoast = self."xf86-video-ast";
  xf86videoati = self."xf86-video-ati";
  xf86videochips = self."xf86-video-chips";
  xf86videocirrus = self."xf86-video-cirrus";
  xf86videodummy = self."xf86-video-dummy";
  xf86videofbdev = self."xf86-video-fbdev";
  xf86videogeode = self."xf86-video-geode";
  xf86videoglide = self."xf86-video-glide";
  xf86videoglint = self."xf86-video-glint";
  xf86videoi128 = self."xf86-video-i128";
  xf86videoi740 = self."xf86-video-i740";
  xf86videointel = self."xf86-video-intel";
  xf86videomga = self."xf86-video-mga";
  xf86videoneomagic = self."xf86-video-neomagic";
  xf86videonewport = self."xf86-video-newport";
  xf86videonouveau = self."xf86-video-nouveau";
  xf86videonv = self."xf86-video-nv";
  xf86videoomap = self."xf86-video-omap";
  xf86videoopenchrome = self."xf86-video-openchrome";
  xf86videoqxl = self."xf86-video-qxl";
  xf86videor128 = self."xf86-video-r128";
  xf86videos3virge = self."xf86-video-s3virge";
  xf86videosavage = self."xf86-video-savage";
  xf86videosiliconmotion = self."xf86-video-siliconmotion";
  xf86videosis = self."xf86-video-sis";
  xf86videosisusb = self."xf86-video-sisusb";
  xf86videosuncg6 = self."xf86-video-suncg6";
  xf86videosunffb = self."xf86-video-sunffb";
  xf86videosunleo = self."xf86-video-sunleo";
  xf86videotdfx = self."xf86-video-tdfx";
  xf86videotga = self."xf86-video-tga";
  xf86videotrident = self."xf86-video-trident";
  xf86videov4l = self."xf86-video-v4l";
  xf86videovboxvideo = self."xf86-video-vboxvideo";
  xf86videovesa = self."xf86-video-vesa";
  xf86videovmware = self."xf86-video-vmware";
  xf86videovoodoo = self."xf86-video-voodoo";
  xf86videowsfb = self."xf86-video-wsfb";
}
