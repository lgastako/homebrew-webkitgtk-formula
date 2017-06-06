USE_STD_ENV = true

class Webkitgtk24 < Formula
  # This formula is ported from (or based on) the following MacPorts port:
  # https://svn.macports.org/repository/macports/trunk/dports/www/webkit-gtk/Portfile

  # also relevant:
  # https://github.com/jralls/gtk-osx-build/blob/master/modulesets/gtk-osx-network.modules#L131-L162

  desc "Full-featured Gtk+ port of the WebKit rendering engine"
  homepage "http://webkitgtk.org"
  url "http://webkitgtk.org/releases/webkitgtk-2.4.9.tar.xz"
  sha256 "afdf29e7828816cad0be2604cf19421e96d96bf493987328ffc8813bb20ac564"

  conflicts_with "webkitgtk"

  needs :cxx11

  # TODO: how can we switch back to superenv while not making parallel make hang?
  env :std if USE_STD_ENV

  option "without-geolocation", "DISABLE geolocation support"
  option "without-video", "DISABLE HTML5 video object support"
  option "without-introspection", "DISABLE GObject introspection"
  option "without-webgl", "DISABLE WebGL support"

  # the original Portfile says (and it seems to hold):
  #
  # > Apple's gnumake (patched 3.81) gets wedged at some point during the build process
  #
  # so we make this optional and disable parallelism if Apple's make is used
  option "with-apple-gnumake", "use Apple's gnumake at /usr/bin/make"

  # let's still keep these to draw attention
  option "without-svg", "(not supported) DISABLE SVG support"
  option "with-gtk-doc", "(not supported) ENABLE documentation generation"
  option "with-accelerated-compositing", "(not supported) ENABLE accelerated compositing support"
  option "with-jit", "(not supported) ENABLE JIT compilation support"
  option "with-web-audio", "(not supported) ENABLE web-audio support"
  option "with-webkit2", "(not supported) ENABLE WebKit 2 support"

  bottle do
    sha256 "a1d3ad20a44da0a303f957a2259be0311a730e94c2f3d716d2f9c300c173adbe" => :el_capitan
    sha256 "500f31ae4c8ebbc19d0a85a8bd2573e8102804ec7f7d9e172e3a01ea689a0865" => :yosemite
    sha256 "0c66a6ad12c4ced2741332a0e6e60510ef2e0a9f739597e9fb2b5117e31454ea" => :mavericks
  end

  depends_on "make"       => :build if build.without? "apple-gnumake"
  depends_on "autoconf"   => :build
  depends_on "automake"   => :build
  depends_on "libtool"    => :build
  depends_on "perl"       => :build
  depends_on "pkg-config" => :build
  depends_on "python"     => :build

  depends_on "glib"
  depends_on "gtk+3"
  depends_on "bison"
  depends_on "flex"
  depends_on "enchant"
  depends_on "libffi"
  depends_on "harfbuzz"
  depends_on "icu4c"
  depends_on "libxslt"
  depends_on "libpng"
  depends_on "libsecret"
  depends_on "libsoup"
  depends_on "sqlite"
  depends_on "webp"

  depends_on "geoclue"               if build.with? "geolocation"
  depends_on "gobject-introspection" if build.with? "introspection"

  # TODO: not sure if web-audio also requires gstreamer & gst-plugins-base
  if (build.with? "web-audio") || (build.with? "video")
    depends_on "gstreamer"
    depends_on "gst-plugins-base"
  end

  # https://lists.webkit.org/pipermail/webkit-gtk/2013-November/001630.html
  depends_on "gtk+" if build.with? "webkit2"

  depends_on "gtk-doc" => :build if build.with? "gtk-doc"

  ### BEGIN BROKEN FEATURE WARNINGS

  # see https://bugs.webkit.org/show_bug.cgi?id=126438
  #     https://bugs.webkit.org/show_bug.cgi?id=126437
  opoo "web-audio support is currently broken; see the formula for details"               if build.with? "web-audio"

  # see https://bugs.webkit.org/show_bug.cgi?id=133293
  opoo "JIT compilation support is currently broken; see the formula for details"         if build.with? "jit"

  # see https://trac.macports.org/ticket/41663
  opoo "accelerated compositing support is currently broken; see the formula for details" if build.with? "accelerated-compositing"

  # see https://lists.webkit.org/pipermail/webkit-gtk/2013-November/001629.html
  #
  # ATTENTION: enable this by default, if possible, but then also see the
  # corresponding patch block below.
  #
  opoo "WebKit 2 support is currently broken; see the formula for details"                if build.with? "webkit2"

  # disabling SVG appears to fail the build
  #    "error: use of undeclared identifier 'CSSValueAlphabetic'"
  #
  # see https://lists.webkit.org/pipermail/webkit-dev/2014-January/026166.html
  opoo "building without SVG support is currently broken; see the formula for details"    if build.without? "svg"

  # odie "GObject introspection support is currently broken; see the formula for details"   if     build.with? "introspection"

  ### END BROKEN FEATURE WARNINGS

  patch :DATA

  def install
    make_command = (build.with? "apple-gnumake") ? "make" : "gmake"

    do_replaces

    @configure_args = [
      "--prefix=#{prefix}",

      # see https://lists.webkit.org/pipermail/webkit-unassigned/2014-November/645071.html
      "--enable-dependency-tracking",

      # https://bugs.webkit.org/show_bug.cgi?id=94488
      # "--disable-dependency-tracking",

      "--enable-x11-target=no",
      "--enable-quartz-target=yes",
      "--enable-wayland-target=no",
    ]

    flags = ["web-audio", "video", "webgl", "geolocation", "svg", "jit",
             "accelerated-compositing", "webkit2", "gtk-doc", "introspection"]
    flags.each do |opt|
      enable_or_disable = (build.with? opt) ? "enable" : "disable"
      @configure_args.push "--#{enable_or_disable}-#{opt}"
    end

    # from the original Portfile
    ENV.append ["CFLAGS", "CXXFLAGS"], "-ftemplate-depth=256"
    ENV.append "CXXFLAGS", "-Wno-c++11-extensions"
    ENV.append "CPPFLAGS", "-DGTEST_USE_OWN_TR1_TUPLE=1"

    # from https://github.com/jralls/gtk-osx-build/blob/master/modulesets/gtk-osx-network.modules#L131-L162
    ENV.append "CXXFLAGS", "-std=gnu++11"

    if (build.with? "apple-gnumake") || !USE_STD_ENV
      # (see also http://stackoverflow.com/a/34206868/247623)
      #
      # without `env :std` and without `ENV.deparallelize`, make will stall at:
      #
      #     libtool: link: (cd ... && rm -rf ...)
      #
      opoo "non-parallelized builds can be very slow"

      ENV.deparallelize
      #
      # consider also (but this seemed to offer no help for me):
      #
      # ENV['LIPO'] = "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/lipo"
    end

    system "autoreconf", "-fvi"

    system "./configure", *@configure_args

    system make_command, "-w", "all", "V=1"
    system make_command, "install-am"
    system make_command, "all-am"
    system make_command, "WebKitGTK-3.0.pot-update"
  end

  def do_replaces
    # https://bugs.webkit.org/show_bug.cgi?id=126433
    inreplace "Source/JavaScriptCore/API/WebKitAvailability.h",
              "defined(__APPLE__)",
              "0"

    # https://bugs.webkit.org/show_bug.cgi?id=58737
    prepend_lines "Source/WTF/wtf/ThreadingPthreads.cpp", [
      "#define OS(MAC_OS_X)",
      "#define PLATFORM(MAC)",
    ]

    # https://bugs.webkit.org/show_bug.cgi?id=126325
    #
    # original reinplace call in Portfile is:
    #     reinplace "s:-stdlib=libstdc\+\+::" ${worksrcpath}/Source/autotools/SetupCompilerFlags.m4
    #
    # ...but the actual line in that file is:
    #     AS_CASE([$CXXFLAGS], [*-stdlib=*], [], [CXXFLAGS="$CXXFLAGS -stdlib=libc++"])
    #
    # so let's try this instead:
    # inreplace "Source/autotools/SetupCompilerFlags.m4",
    #           "-stdlib=libc++",
    #           ""

    # https://bugs.webkit.org/show_bug.cgi?id=126329
    inreplace "Source/JavaScriptCore/API/JSBase.h",
              /^#define JSC_OBJC_API_ENABLED.*$/,
              "#define JSC_OBJC_API_ENABLED 0"
  end

  def prepend_lines(fname, lines)
    old = File.read(fname)
    lines_str = lines.map { |x| x + "\n" }.join
    new = lines_str + old
    File.open(fname, "w") { |f| f.puts new }
  end
end


__END__
@@@
@@@ orig: https://svn.macports.org/repository/macports/trunk/dports/www/webkit-gtk/files/clang-assertions.patch
@@@
--- a/Source/WTF/wtf/Assertions.h	2013-01-18 15:03:57.000000000 -0800
+++ b/Source/WTF/wtf/Assertions.h	2013-01-18 15:04:46.000000000 -0800
@@ -371,7 +371,8 @@ while (0)
 // a function. Hence it uses macro naming convention.
 #pragma clang diagnostic push
 #pragma clang diagnostic ignored "-Wmissing-noreturn"
-static inline void UNREACHABLE_FOR_PLATFORM()
+__attribute__ ((__always_inline__))
+static __inline__ void UNREACHABLE_FOR_PLATFORM()
 {
     ASSERT_NOT_REACHED();
 }

@@@
@@@ https://bugs.webkit.org/show_bug.cgi?id=65811
@@@ orig: http://svn.macports.org/repository/macports/trunk/dports/www/webkit-gtk/files/case-insensitive.patch
@@@
--- a/Source/WebCore/platform/text/TextCodecUTF8.h	2012-04-12 17:24:24.000000000 -0700
+++ b/Source/WebCore/platform/text/TextCodecUTF8.h	2012-04-12 17:46:05.000000000 -0700
@@ -28,6 +28,9 @@
 
 #include "TextCodec.h"
 
+/* https://bugs.webkit.org/show_bug.cgi?id=65811 */
+#include "../../../JavaScriptCore/icu/unicode/utf8.h"
+
 namespace WebCore {
 
 class TextCodecUTF8 : public TextCodec {

@@@
@@@ our-icu.patch: No upstream bug report, probably not wanted
@@@ orig: https://svn.macports.org/repository/macports/trunk/dports/www/webkit-gtk/files/our-icu.patch
@@@
--- a/Source/autotools/FindDependencies.m4	2015-12-11 16:25:59.000000000 +0200
+++ b/Source/autotools/FindDependencies.m4	2015-12-11 16:26:02.000000000 +0200
@@ -104,10 +104,6 @@
 
 # TODO: use pkg-config (after CFLAGS in their .pc files are cleaned up).
 case "$host" in
-    *-*-darwin*)
-        UNICODE_CFLAGS="-I$srcdir/Source/JavaScriptCore/icu -I$srcdir/Source/WebCore/icu"
-        UNICODE_LIBS="-licucore"
-        ;;
     *-*-mingw*)
 	PKG_CHECK_MODULES(ICU, icu-i18n, ,)
 	if test "x$ICU_LIBS" = "x" ; then

@@@
@@@ ruby-1.8.patch: https://bugs.webkit.org/show_bug.cgi?id=126327
@@@ orig: https://svn.macports.org/repository/macports/trunk/dports/www/webkit-gtk/files/ruby-1.8.patch
@@@
--- a/Source/JavaScriptCore/offlineasm/offsets.rb	2012-11-23 14:12:16.000000000 -0600
+++ b/Source/JavaScriptCore/offlineasm/offsets.rb	2013-01-22 19:35:47.000000000 -0600
@@ -108,7 +108,11 @@
     File.open(file, "rb") {
         | inp |
         loop {
-            byte = inp.getbyte
+            if RUBY_VERSION >= '1.8.7'
+              byte = inp.getbyte
+            else
+              byte = inp.getc
+            end
             break unless byte
             fileBytes << byte
         }

@@@
@@@ quartz-webcore.patch: https://bugs.webkit.org/show_bug.cgi?id=126326
@@@ orig: https://svn.macports.org/repository/macports/trunk/dports/www/webkit-gtk/files/quartz-webcore.patch
@@@
--- a/Source/WebCore/plugins/PluginView.cpp	2015-05-20 02:03:24.000000000 -0700
+++ b/Source/WebCore/plugins/PluginView.cpp	2015-08-08 15:02:30.000000000 -0700
@@ -839,7 +839,7 @@
 #if defined(XP_MACOSX)
     , m_contextRef(0)
 #endif
-#if defined(XP_UNIX) && ENABLE(NETSCAPE_PLUGIN_API)
+#if PLATFORM(X11) && ENABLE(NETSCAPE_PLUGIN_API)
     , m_hasPendingGeometryChange(true)
     , m_drawable(0)
     , m_visual(0)
--- a/Source/WebCore/plugins/PluginView.h	2015-05-20 02:03:24.000000000 -0700
+++ b/Source/WebCore/plugins/PluginView.h	2015-08-08 15:02:30.000000000 -0700
@@ -378,7 +378,7 @@
         void setNPWindowIfNeeded();
 #endif
 
-#if defined(XP_UNIX) && ENABLE(NETSCAPE_PLUGIN_API)
+#if PLATFORM(X11) && ENABLE(NETSCAPE_PLUGIN_API)
         bool m_hasPendingGeometryChange;
         Pixmap m_drawable;
         Visual* m_visual;
--- a/Source/WebCore/GNUmakefile.list.am	2015-06-16 09:12:37.000000000 +0200
+++ b/Source/WebCore/GNUmakefile.list.am	2015-06-16 09:13:38.000000000 +0200
@@ -6315,11 +6315,9 @@
 
 if TARGET_QUARTZ
 if !TARGET_X11
-if ENABLE_WEBKIT2
 webcore_sources += \
 	Source/WebCore/plugins/PluginPackageNone.cpp \
 	Source/WebCore/plugins/PluginViewNone.cpp
-endif # END ENABLE_WEBKIT2
 endif # END !TARGET_X11
 platformgtk_sources += \
 	Source/WebCore/platform/cairo/WidgetBackingStoreCairo.h \

@@@
@@@ orig: https://svn.macports.org/repository/macports/trunk/dports/www/webkit-gtk/files/quartz-duplicate-symbols.patch
@@@ ... but doesn't seem to be needed
@@@

@@@ 
@@@ according to
@@@  
@@@     https://lists.webkit.org/pipermail/webkit-gtk/2015-December/002474.html
@@@  
@@@ this patch should not be needed, but without it, we get
@@@  
@@@   Source/WebCore/platform/audio/gstreamer/FFTFrameGStreamer.cpp:46:38: error: use of undeclared identifier 'GstFFTF32Complex'
@@@       , m_complexData(std::make_unique<GstFFTF32Complex[]>(unpackedFFTDataSize(m_FFTSize)))
@@@        				^
@@@  
@@@ gstreamer.patch: https://bugs.webkit.org/show_bug.cgi?id=126437
@@@ orig: https://svn.macports.org/repository/macports/trunk/dports/www/webkit-gtk/files/gstreamer.patch
@@@ 
--- a/Source/WebCore/platform/audio/FFTFrame.h	2014-01-23 11:33:19.000000000 -0800
+++ b/Source/WebCore/platform/audio/FFTFrame.h	2014-02-05 17:36:33.000000000 -0800
@@ -47,13 +47,6 @@
 #include "mkl_dfti.h"
 #endif // USE(WEBAUDIO_MKL)
 
-#if USE(WEBAUDIO_GSTREAMER)
-#include <glib.h>
-G_BEGIN_DECLS
-#include <gst/fft/gstfftf32.h>
-G_END_DECLS
-#endif // USE(WEBAUDIO_GSTREAMER)
-
 #if USE(WEBAUDIO_OPENMAX_DL_FFT)
 #include "dl/sp/api/armSP.h"
 #include "dl/sp/api/omxSP.h"
@@ -63,6 +56,13 @@ struct RDFTContext;
 
 #endif // !USE_ACCELERATE_FFT
 
+#if USE(WEBAUDIO_GSTREAMER)
+#include <glib.h>
+G_BEGIN_DECLS
+#include <gst/fft/gstfftf32.h>
+G_END_DECLS
+#endif // USE(WEBAUDIO_GSTREAMER)
+
 #if USE(WEBAUDIO_IPP)
 #include <ipps.h>
 #endif // USE(WEBAUDIO_IPP)


@@@
@@@ leopard-platform.patch: https://bugs.webkit.org/show_bug.cgi?id=140143
@@@ orig: https://svn.macports.org/repository/macports/trunk/dports/www/webkit-gtk/files/leopard-platform.patch
@@@
--- a/Source/WTF/wtf/Platform.h	2015-01-06 13:30:52.000000000 -0800
+++ b/Source/WTF/wtf/Platform.h	2015-01-06 13:42:15.000000000 -0800
@@ -590,11 +590,14 @@
 
 #if OS(DARWIN)
 
+#if __MAC_OS_X_VERSION_MIN_REQUIRED >= 1060 || PLATFORM(IOS)
 #define HAVE_DISPATCH_H 1
-#define HAVE_MADV_FREE 1
 #define HAVE_MADV_FREE_REUSE 1
-#define HAVE_MERGESORT 1
 #define HAVE_PTHREAD_SETNAME_NP 1
+#endif
+
+#define HAVE_MADV_FREE 1
+#define HAVE_MERGESORT 1
 #define HAVE_READLINE 1
 #define HAVE_SYS_TIMEB_H 1
 #define WTF_USE_ACCELERATE 1

@@@
@@@ leopard-malloc.patch: https://bugs.webkit.org/show_bug.cgi?id=140143
@@@ orig: https://svn.macports.org/repository/macports/trunk/dports/www/webkit-gtk/files/leopard-malloc.patch
@@@
--- a/Source/WTF/wtf/FastMalloc.cpp	2015-01-07 16:04:31.000000000 -0800
+++ b/Source/WTF/wtf/FastMalloc.cpp	2015-01-07 16:06:05.000000000 -0800
@@ -5095,8 +5095,13 @@ void* FastMallocZone::zoneRealloc(malloc
 extern "C" {
 malloc_introspection_t jscore_fastmalloc_introspection = { &FastMallocZone::enumerate, &FastMallocZone::goodSize, &FastMallocZone::check, &FastMallocZone::print,
     &FastMallocZone::log, &FastMallocZone::forceLock, &FastMallocZone::forceUnlock, &FastMallocZone::statistics
+
+#if OS(IOS) || __MAC_OS_X_VERSION_MAX_ALLOWED >= 1060
     , 0 // zone_locked will not be called on the zone unless it advertises itself as version five or higher.
+#endif
+#if OS(IOS) || __MAC_OS_X_VERSION_MAX_ALLOWED >= 1070
     , 0, 0, 0, 0 // These members will not be used unless the zone advertises itself as version seven or higher.
+#endif
 
     };
 }

@@@
@@@ libedit.patch: https://bugs.webkit.org/show_bug.cgi?id=127059
@@@ orig: https://svn.macports.org/repository/macports/trunk/dports/www/webkit-gtk/files/libedit.patch
@@@
--- a/Source/JavaScriptCore/GNUmakefile.am	2014-01-12 11:11:12.000000000 -0800
+++ b/Source/JavaScriptCore/GNUmakefile.am	2014-01-15 12:33:06.000000000 -0800
@@ -26,6 +26,7 @@ libjavascriptcoregtk_@WEBKITGTK_API_MAJO
 	$(javascriptcore_sources)
 
 libjavascriptcoregtk_@WEBKITGTK_API_MAJOR_VERSION@_@WEBKITGTK_API_MINOR_VERSION@_la_LIBADD = \
+	-ledit \
 	-lpthread \
 	libWTF.la \
 	$(GLIB_LIBS) \


@@@
@@@ remove-cf-available.patch: https://trac.macports.org/ticket/49849
@@@ orig: https://svn.macports.org/repository/macports/trunk/dports/www/webkit-gtk/files/remove-cf-available.patch
@@@
diff -ur Source/JavaScriptCore/API.orig/JSBasePrivate.h Source/JavaScriptCore/API/JSBasePrivate.h
--- a/Source/JavaScriptCore/API/JSBasePrivate.h	2015-12-07 15:46:53.000000000 -0800
+++ b/Source/JavaScriptCore/API/JSBasePrivate.h	2015-12-07 15:50:37.000000000 -0800
@@ -43,7 +43,7 @@
 garbage collector to collect soon, hoping to reclaim that large non-GC memory
 region.
 */
-JS_EXPORT void JSReportExtraMemoryCost(JSContextRef ctx, size_t size) CF_AVAILABLE(10_6, 7_0);
+JS_EXPORT void JSReportExtraMemoryCost(JSContextRef ctx, size_t size);
 
 JS_EXPORT void JSDisableGCTimer(void);
 
diff -ur Source/JavaScriptCore/API.orig/JSContextRef.h Source/JavaScriptCore/API/JSContextRef.h
--- a/Source/JavaScriptCore/API/JSContextRef.h	2015-12-07 15:46:53.000000000 -0800
+++ b/Source/JavaScriptCore/API/JSContextRef.h	2015-12-07 15:52:46.000000000 -0800
@@ -48,7 +48,7 @@
  synchronization is required.
 @result The created JSContextGroup.
 */
-JS_EXPORT JSContextGroupRef JSContextGroupCreate() CF_AVAILABLE(10_6, 7_0);
+JS_EXPORT JSContextGroupRef JSContextGroupCreate();
 
 /*!
 @function
@@ -56,14 +56,14 @@
 @param group The JSContextGroup to retain.
 @result A JSContextGroup that is the same as group.
 */
-JS_EXPORT JSContextGroupRef JSContextGroupRetain(JSContextGroupRef group) CF_AVAILABLE(10_6, 7_0);
+JS_EXPORT JSContextGroupRef JSContextGroupRetain(JSContextGroupRef group);
 
 /*!
 @function
 @abstract Releases a JavaScript context group.
 @param group The JSContextGroup to release.
 */
-JS_EXPORT void JSContextGroupRelease(JSContextGroupRef group) CF_AVAILABLE(10_6, 7_0);
+JS_EXPORT void JSContextGroupRelease(JSContextGroupRef group);
 
 /*!
 @function
@@ -78,7 +78,7 @@
  NULL to use the default object class.
 @result A JSGlobalContext with a global object of class globalObjectClass.
 */
-JS_EXPORT JSGlobalContextRef JSGlobalContextCreate(JSClassRef globalObjectClass) CF_AVAILABLE(10_5, 7_0);
+JS_EXPORT JSGlobalContextRef JSGlobalContextCreate(JSClassRef globalObjectClass);
 
 /*!
 @function
@@ -92,7 +92,7 @@
 @result A JSGlobalContext with a global object of class globalObjectClass and a context
  group equal to group.
 */
-JS_EXPORT JSGlobalContextRef JSGlobalContextCreateInGroup(JSContextGroupRef group, JSClassRef globalObjectClass) CF_AVAILABLE(10_6, 7_0);
+JS_EXPORT JSGlobalContextRef JSGlobalContextCreateInGroup(JSContextGroupRef group, JSClassRef globalObjectClass);
 
 /*!
 @function
@@ -123,7 +123,7 @@
 @param ctx The JSContext whose group you want to get.
 @result ctx's group.
 */
-JS_EXPORT JSContextGroupRef JSContextGetGroup(JSContextRef ctx) CF_AVAILABLE(10_6, 7_0);
+JS_EXPORT JSContextGroupRef JSContextGetGroup(JSContextRef ctx);
 
 /*!
 @function
@@ -131,7 +131,7 @@
 @param ctx The JSContext whose global context you want to get.
 @result ctx's global context.
 */
-JS_EXPORT JSGlobalContextRef JSContextGetGlobalContext(JSContextRef ctx) CF_AVAILABLE(10_7, 7_0);
+JS_EXPORT JSGlobalContextRef JSContextGetGlobalContext(JSContextRef ctx);
 
 /*!
 @function
diff -ur Source/JavaScriptCore/API.orig/JSContextRefPrivate.h Source/JavaScriptCore/API/JSContextRefPrivate.h
--- a/Source/JavaScriptCore/API/JSContextRefPrivate.h	2015-12-07 15:46:53.000000000 -0800
+++ b/Source/JavaScriptCore/API/JSContextRefPrivate.h	2015-12-07 15:53:30.000000000 -0800
@@ -44,7 +44,7 @@
 @param ctx The JSContext whose backtrace you want to get
 @result A string containing the backtrace
 */
-JS_EXPORT JSStringRef JSContextCreateBacktrace(JSContextRef ctx, unsigned maxStackSize) CF_AVAILABLE(10_6, 7_0);
+JS_EXPORT JSStringRef JSContextCreateBacktrace(JSContextRef ctx, unsigned maxStackSize);
     
 
 /*! 
@@ -85,14 +85,14 @@
  need to call JSContextGroupSetExecutionTimeLimit before you start executing
  any scripts.
 */
-JS_EXPORT void JSContextGroupSetExecutionTimeLimit(JSContextGroupRef, double limit, JSShouldTerminateCallback, void* context) CF_AVAILABLE(10_6, 7_0);
+JS_EXPORT void JSContextGroupSetExecutionTimeLimit(JSContextGroupRef, double limit, JSShouldTerminateCallback, void* context);
 
 /*!
 @function
 @abstract Clears the script execution time limit.
 @param group The JavaScript context group that the time limit is cleared on.
 */
-JS_EXPORT void JSContextGroupClearExecutionTimeLimit(JSContextGroupRef) CF_AVAILABLE(10_6, 7_0);
+JS_EXPORT void JSContextGroupClearExecutionTimeLimit(JSContextGroupRef);
 
 #ifdef __cplusplus
 }
diff -ur Source/JavaScriptCore/API.orig/JSObjectRef.h Source/JavaScriptCore/API/JSObjectRef.h
--- a/Source/JavaScriptCore/API/JSObjectRef.h	2015-12-07 15:46:53.000000000 -0800
+++ b/Source/JavaScriptCore/API/JSObjectRef.h	2015-12-07 15:54:25.000000000 -0800
@@ -441,7 +441,7 @@
  @discussion The behavior of this function does not exactly match the behavior of the built-in Array constructor. Specifically, if one argument 
  is supplied, this function returns an array with one element.
  */
-JS_EXPORT JSObjectRef JSObjectMakeArray(JSContextRef ctx, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception) CF_AVAILABLE(10_6, 7_0);
+JS_EXPORT JSObjectRef JSObjectMakeArray(JSContextRef ctx, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception);
 
 /*!
  @function
@@ -452,7 +452,7 @@
  @param exception A pointer to a JSValueRef in which to store an exception, if any. Pass NULL if you do not care to store an exception.
  @result A JSObject that is a Date.
  */
-JS_EXPORT JSObjectRef JSObjectMakeDate(JSContextRef ctx, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception) CF_AVAILABLE(10_6, 7_0);
+JS_EXPORT JSObjectRef JSObjectMakeDate(JSContextRef ctx, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception);
 
 /*!
  @function
@@ -463,7 +463,7 @@
  @param exception A pointer to a JSValueRef in which to store an exception, if any. Pass NULL if you do not care to store an exception.
  @result A JSObject that is a Error.
  */
-JS_EXPORT JSObjectRef JSObjectMakeError(JSContextRef ctx, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception) CF_AVAILABLE(10_6, 7_0);
+JS_EXPORT JSObjectRef JSObjectMakeError(JSContextRef ctx, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception);
 
 /*!
  @function
@@ -474,7 +474,7 @@
  @param exception A pointer to a JSValueRef in which to store an exception, if any. Pass NULL if you do not care to store an exception.
  @result A JSObject that is a RegExp.
  */
-JS_EXPORT JSObjectRef JSObjectMakeRegExp(JSContextRef ctx, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception) CF_AVAILABLE(10_6, 7_0);
+JS_EXPORT JSObjectRef JSObjectMakeRegExp(JSContextRef ctx, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception);
 
 /*!
 @function
diff -ur Source/JavaScriptCore/API.orig/JSValueRef.h Source/JavaScriptCore/API/JSValueRef.h
--- a/Source/JavaScriptCore/API/JSValueRef.h	2015-12-07 15:46:53.000000000 -0800
+++ b/Source/JavaScriptCore/API/JSValueRef.h	2015-12-07 15:55:30.000000000 -0800
@@ -218,7 +218,7 @@
  @param string   The JSString containing the JSON string to be parsed.
  @result         A JSValue containing the parsed value, or NULL if the input is invalid.
  */
-JS_EXPORT JSValueRef JSValueMakeFromJSONString(JSContextRef ctx, JSStringRef string) CF_AVAILABLE(10_7, 7_0);
+JS_EXPORT JSValueRef JSValueMakeFromJSONString(JSContextRef ctx, JSStringRef string);
 
 /*!
  @function
@@ -229,7 +229,7 @@
  @param exception A pointer to a JSValueRef in which to store an exception, if any. Pass NULL if you do not care to store an exception.
  @result         A JSString with the result of serialization, or NULL if an exception is thrown.
  */
-JS_EXPORT JSStringRef JSValueCreateJSONString(JSContextRef ctx, JSValueRef value, unsigned indent, JSValueRef* exception) CF_AVAILABLE(10_7, 7_0);
+JS_EXPORT JSStringRef JSValueCreateJSONString(JSContextRef ctx, JSValueRef value, unsigned indent, JSValueRef* exception);
 
 /* Converting to primitive values */





@@@
@@@ patches that are not needed and/or whose diffs don't apply
@@@
@@@ see https://bugs.webkit.org/show_bug.cgi?id=116467
@@@
@@@ ...but WKBaseMac.h does not even seem to exist at all
@@@
@@@ --- a/Source/WebKit2/Shared/API/c/WKBase.h	
@@@ +++ b/Source/WebKit2/Shared/API/c/WKBase.h	
@@@ @@ -41,7 +41,7 @@ 
@@@  #include <WebKit2/WKBaseEfl.h>
@@@  #endif
@@@  
@@@ -#if defined(__APPLE__)
@@@ +#if defined(__APPLE__) && !defined(BUILDING_QT__)
@@@  #include <WebKit2/WKBaseMac.h>
@@@  #endif


@@@
@@@ see https://bugs.webkit.org/show_bug.cgi?id=131267
@@@ ????? but this doesn't seem to be required for a successful compilation
@@@
@@@
@@@ --- a/Source/WebCore/Modules/webaudio/AudioBuffer.cpp	2015-12-11 17:53:52.000000000 +0200
@@@ +++ b/Source/WebCore/Modules/webaudio/AudioBuffer.cpp	2015-12-11 17:52:45.000000000 +0200
@@@ @@ -39,6 +39,7 @@
@@@  #include "ExceptionCodePlaceholder.h"
@@@  
@@@  #include <runtime/Operations.h>
@@@ +#include <runtime/JSCInlines.h>
@@@  #include <runtime/TypedArrayInlines.h>
@@@  
@@@  namespace WebCore {
