{ stdenv
, lib
, fetchFromGitHub
, imagemagickBig
, pkg-config
, withXorg ? true
, libX11
, libv4l
, qtbase
, qtx11extras
, wrapQtAppsHook
, wrapGAppsHook
, gtk3
, xmlto
, docbook_xsl
, autoreconfHook
, dbus
, enableVideo ? stdenv.isLinux
  # The implementation is buggy and produces an error like
  # Name Error (Connection ":1.4380" is not allowed to own the service "org.linuxtv.Zbar" due to security policies in the configuration file)
  # for every scanned code.
  # see https://github.com/mchehab/zbar/issues/104
, enableDbus ? false
, libintl
, libiconv
, Foundation
}:

stdenv.mkDerivation rec {
  pname = "zbar";
  version = "0.23.90";

  outputs = [ "out" "lib" "dev" "doc" "man" ];

  src = fetchFromGitHub {
    owner = "mchehab";
    repo = "zbar";
    rev = version;
    sha256 = "sha256-FvV7TMc4JbOiRjWLka0IhtpGGqGm5fis7h870OmJw2U=";
  };

  nativeBuildInputs = [
    pkg-config
    xmlto
    autoreconfHook
    docbook_xsl
  ] ++ lib.optionals enableVideo [
    wrapGAppsHook
    wrapQtAppsHook
  ];

  buildInputs = [
    imagemagickBig
    libintl
  ] ++ lib.optionals stdenv.isDarwin [
    libiconv
    Foundation
  ] ++ lib.optionals enableDbus [
    dbus
  ] ++ lib.optionals withXorg [
    libX11
  ] ++ lib.optionals enableVideo [
    libv4l
    gtk3
    qtbase
    qtx11extras
  ];

  # Disable assertions which include -dev QtBase file paths.
  NIX_CFLAGS_COMPILE = "-DQT_NO_DEBUG";

  configureFlags = [
    "--without-python"
  ] ++ (if enableDbus then [
    "--with-dbusconfdir=${placeholder "out"}/share"
  ] else [
    "--without-dbus"
  ]) ++ (if enableVideo then [
    "--with-gtk=gtk3"
  ] else [
    "--disable-video"
    "--without-gtk"
    "--without-qt"
  ]);

  dontWrapQtApps = true;
  dontWrapGApps = true;

  postFixup = lib.optionalString enableVideo ''
    wrapGApp "$out/bin/zbarcam-gtk"
    wrapQtApp "$out/bin/zbarcam-qt"
  '';

  enableParallelBuilding = true;

  meta = with lib; {
    description = "Bar code reader";
    longDescription = ''
      ZBar is an open source software suite for reading bar codes from various
      sources, such as video streams, image files and raw intensity sensors. It
      supports many popular symbologies (types of bar codes) including
      EAN-13/UPC-A, UPC-E, EAN-8, Code 128, Code 39, Interleaved 2 of 5 and QR
      Code.
    '';
    maintainers = with maintainers; [ delroth raskin ];
    platforms = platforms.unix;
    license = licenses.lgpl21;
    homepage = "https://github.com/mchehab/zbar";
    mainProgram = "zbarimg";
  };
}
