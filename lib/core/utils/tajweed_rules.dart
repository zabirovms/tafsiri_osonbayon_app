import 'package:flutter/material.dart';

/// List of HTML rule tag strings for expanding compressed Tajweed JSON (r0, r1, ...)
final List<String> tajweedRulesExpansionList = [
  "<rule class=ham_wasl>",
  "<rule class=laam_shamsiyah>",
  "<rule class=madda_normal>",
  "<rule class=madda_permissible>",
  "<rule class='ham_wasl'>",
  "<rule class='laam_shamsiyah'>",
  "<rule class='madda_normal'>",
  "<rule class=madda_necessary>",
  "<rule class=idgham_wo_ghunnah>",
  "<rule class=slnt>",
  "<rule class=ghunnah>",
  "<rule class=qalaqah>",
  "<rule class=ikhafa>",
  "<rule class=madda_obligatory_monfasel>",
  "<rule class=madda_obligatory_mottasel>",
  "<rule class=idgham_ghunnah>",
  "<rule class=ikhafa_shafawi>",
  "<rule class=idgham_shafawi>",
  "<rule class=iqlab>",
  "<rule class='idgham_ghunnah'>",
  "<rule class='ikhafa'>",
  "<rule class='madda_obligatory_mottasel'>",
  "<rule class='madda_permissible'>",
  "<rule class='ikhafa_shafawi'>",
  "<rule class='qalaqah'>",
  "<rule class='iqlab'>",
  "<rule class='idgham_wo_ghunnah'>",
  "<rule class='ghunnah'>",
  "<rule class='slnt'>",
  "<rule class=idgham_mutajanisayn>",
  "<rule class='idgham_shafawi'>",
  "<rule class=idgham_mutaqaribayn>",
  "<rule class='madda_obligatory_monfasel'>",
  "<rule class='idgham_mutajanisayn'>",
  "<rule class=\"ikhafa_shafawi\" data-bs-original-title=\"\" title=\"\">",
];

// Light Theme Tajweed Colors
const Color lightMaddaNecessary = Color(0xFFa9045c);
const Color lightIdghamGhunnah = Color(0xFF169200);
const Color lightIkhafaShafawi = Color(0xFFd500b7);
const Color lightIdghamWoGhunnah = Color(0xFF169200);
const Color lightSlnt = Color(0xFF888888);
const Color lightIdghamMutajanisayn = Color(0xFF888888);
const Color lightGhunnah = Color(0xFFff7e1e);
const Color lightIdghamMutaqaribayn = Color(0xFF888888);
const Color lightHamWasl = Color(0xFF888888);
const Color lightQalaqah = Color(0xFF009ee6);
const Color lightMaddaObligatoryMonfasel = Color(0xFFf2007f);
const Color lightMaddaNormal = Color(0xFF537fff);
const Color lightIkhafa = Color(0xFF9400a8);
const Color lightIdghamShafawi = Color(0xFF58b800);
const Color lightLaamShamsiyah = Color(0xFF888888);
const Color lightMaddaPermissible = Color(0xFFf38e02);
const Color lightMaddaObligatoryMottasel = Color(0xFFf2007f);
const Color lightIqlab = Color(0xFF26bffd);
const Color lightCustomAlefMaksora = Color(0xFF6a0dad);

// Dark Theme Tajweed Colors (Adjusted for high contrast on dark background)
const Color darkMaddaNecessary = Color(0xFFe65aa7);
const Color darkIdghamGhunnah = Color(0xFF57d342);
const Color darkIkhafaShafawi = Color(0xFFf050d7);
const Color darkIdghamWoGhunnah = Color(0xFF57d342);
const Color darkSlnt = Color(0xFFaaaaaa);
const Color darkIdghamMutajanisayn = Color(0xFFaaaaaa);
const Color darkGhunnah = Color(0xFFff9a50);
const Color darkIdghamMutaqaribayn = Color(0xFFaaaaaa);
const Color darkHamWasl = Color(0xFFaaaaaa);
const Color darkQalaqah = Color(0xFF4dc5ff);
const Color darkMaddaObligatoryMonfasel = Color(0xFFfa5aa7);
const Color darkMaddaNormal = Color(0xFF80a0ff);
const Color darkIkhafa = Color(0xFFca50e0);
const Color darkIdghamShafawi = Color(0xFF85e030);
const Color darkLaamShamsiyah = Color(0xFFaaaaaa);
const Color darkMaddaPermissible = Color(0xFFffb040);
const Color darkMaddaObligatoryMottasel = Color(0xFFfa5aa7);
const Color darkIqlab = Color(0xFF60d0ff);
const Color darkCustomAlefMaksora = Color(0xFFb070f0);

/// Helper to get the color palette map for Tajweed rule classes based on current theme brightness
Map<String, Color> getTajweedThemeColors(bool isLight) {
  return {
    "ghunnah": isLight ? lightGhunnah : darkGhunnah,
    "idgham_shafawi": isLight ? lightIdghamShafawi : darkIdghamShafawi,
    "iqlab": isLight ? lightIqlab : darkIqlab,
    "ikhafa_shafawi": isLight ? lightIkhafaShafawi : darkIkhafaShafawi,
    "qalaqah": isLight ? lightQalaqah : darkQalaqah,
    "idgham_ghunnah": isLight ? lightIdghamGhunnah : darkIdghamGhunnah,
    "idgham_wo_ghunnah": isLight ? lightIdghamWoGhunnah : darkIdghamWoGhunnah,
    "ikhafa": isLight ? lightIkhafa : darkIkhafa,
    "madda_normal": isLight ? lightMaddaNormal : darkMaddaNormal,
    "madda_necessary": isLight ? lightMaddaNecessary : darkMaddaNecessary,
    "madda_permissible": isLight ? lightMaddaPermissible : darkMaddaPermissible,
    "madda_obligatory_mottasel": isLight ? lightMaddaObligatoryMottasel : darkMaddaObligatoryMottasel,
    "madda_obligatory_monfasel": isLight ? lightMaddaObligatoryMonfasel : darkMaddaObligatoryMonfasel,
    "ham_wasl": isLight ? lightHamWasl : darkHamWasl,
    "laam_shamsiyah": isLight ? lightLaamShamsiyah : darkLaamShamsiyah,
    "slnt": isLight ? lightSlnt : darkSlnt,
    "idgham_mutajanisayn": isLight ? lightIdghamMutajanisayn : darkIdghamMutajanisayn,
    "idgham_mutaqaribayn": isLight ? lightIdghamMutaqaribayn : darkIdghamMutaqaribayn,
    "custom-alef-maksora": isLight ? lightCustomAlefMaksora : darkCustomAlefMaksora,
  };
}
