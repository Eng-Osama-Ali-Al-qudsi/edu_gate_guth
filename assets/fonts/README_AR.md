# ملفات خط Cairo المطلوبة

يعتمد التطبيق على **Cairo Variable TTF** الأصلي المنشور في مستودع Google Fonts الرسمي. ملف TTF واحد متغير يوفّر محور الوزن `wght` من 200 إلى 1000، ولذلك يغطي الأوزان المستخدمة في الواجهة (Regular / Medium / SemiBold / Bold) دون إنشاء ملفات بديلة أو استخدام حزمة Google Fonts.

## الملف المطلوب وضعه هنا

- الاسم المحلي المطلوب: `Cairo-Variable.ttf`
- المسار: `assets/fonts/Cairo-Variable.ttf`
- المصدر الرسمي المباشر: https://raw.githubusercontent.com/google/fonts/main/ofl/cairo/Cairo%5Bslnt%2Cwght%5D.ttf
- صفحة المصدر: https://github.com/google/fonts/tree/main/ofl/cairo
رابط الرخصة الرسمية: https://raw.githubusercontent.com/google/fonts/main/ofl/cairo/OFL.txt
- اسم الملف في مستودع Google Fonts: `Cairo[slnt,wght].ttf`
- حجم الملف المنشور في فهرس Google Fonts: 599,548 بايت.
- SHA-1 للبايتات الخام: `c6c60f666700c17bd38833483b5b14e7a2ebf029`.
- SHA-256 للبايتات الخام: `667c987182391c91f4e57a2f455b1794fb5e3ee6ca4ef3383e86bb690fa9c964`.
- Git blob SHA-1: `25641b1c828857698457bcd9f5a102616b4e8033` (يُحسب على `blob <length> NUL + file bytes`، وليس SHA-1 للبايتات الخام).

نزّل الملف من المصدر الرسمي، ثم أعد تسميته إلى `Cairo-Variable.ttf` وضعه في هذا المجلد. لا تنشئ ملفاً فارغاً ولا تستخدم خطاً بديلاً.

## الترخيص

الملف `OFL.txt` المرفق هو نص رخصة SIL Open Font License 1.1 الرسمية الخاصة بعائلة Cairo، مطابق لملف `google/fonts/ofl/cairo/OFL.txt` (4,473 بايت، Git blob SHA-1: `f6e87d489b3f459dde4e0f457fdd63e1f39bfe67`).

## التسجيل

تم تسجيل العائلة `Cairo` في `pubspec.yaml` تحت `flutter: fonts:`، والثيم العام يستخدم `fontFamily: Cairo`. ملف الخط الثنائي غير مضمّن في حزمة المصدر الحالية؛ لذلك يجب وضع الملف أعلاه قبل تشغيل سكربت البناء.
