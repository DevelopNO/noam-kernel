# Noam Kernel

קרנל לימודי ל־x86_64, כתוב ב־C11 וב־GNU Assembly. אבן הדרך הראשונה
ממומשת: טעינת Multiboot v1, מעבר ל־64 ביט והדפסת `KERNEL_BOOT_OK` מתוך הקרנל.

## סביבת פיתוח ובנייה

נדרשת סביבת Linux x86_64 עם GCC, binutils, GNU Make, Python 3, QEMU ו־GDB.
בסביבת Debian/Ubuntu עם הרשאת התקנה:

```sh
sudo apt-get update
sudo apt-get install --no-install-recommends build-essential binutils qemu-system-x86 gdb python3
make all
make test
make test-gdb
```

בסביבת הענן הנוכחית המהדר כבר מותקן ואין הרשאת root. הסקריפט הבא מוריד
חבילות Debian/Ubuntu מהמקורות המוגדרים, מחלץ אותן מקומית ויוצר wrappers
עם נתיבי ספריות וקושחה. הוא אינו מתקין חבילות במערכת; הוא מיועד למכונה
שכבר כוללת את כלי הבנייה והתלויות הבסיסיות שלה.

```sh
sh scripts/setup-local-tools.sh
export PATH="$PWD/.local-tools/bin:$PATH"
make all
make test
make test-gdb
```

אפשר לתת לסקריפט נתיב חלופי. בהרצה שאומתה השתמשנו ב־
`sh scripts/setup-local-tools.sh /workspace/kernel-tools`, ואז הוספנו
`/workspace/kernel-tools/bin` ל־`PATH`. נדרשת רשת להורדת החבילות; במקרה
של כשל זמני בהורדה ניתן להריץ שוב. ארכיונים שכבר הורדו נשמרים במטמון.

## תוצרים ופקודות

| פקודה | תוצאה |
| --- | --- |
| `make all` | `build/kernel.bin` לטעינה ו־`build/kernel.elf` עם סמלי דיבוג |
| `make run` | הרצה ב־QEMU עם פלט סריאלי למסוף; Ctrl-C לסיום |
| `make test` | אימות הכותרת והסמלים, ואתחול אורח אמיתי עם מגבלת 10 שניות |
| `make test-gdb` | עצירה ב־`kernel_main` ואימות רגיסטרים, long mode ויישור מחסנית |
| `make debug` | QEMU מושהה עם GDB ב־`127.0.0.1:1234` |
| `make clean` | מחיקת תיקיית התוצרים |

ניתן להגדיר `QEMU`,‏ `GDB` ו־`PYTHON` דרך Make. הרצת הבדיקות נעשית משורש
הריפו. בדיקת האתחול שומרת את `build/serial.log`,‏ `build/qemu.stderr.log`
ו־`build/boot-result.json`, הכולל מגבלת זמן, קוד יציאה וסיבת הסיום.
הקרנל נעצר ב־`hlt` אחרי ההדפסה; הבדיקה מסיימת את QEMU בעצמה אחרי זיהוי
הסמן. קוד היציאה לבדו אינו מעיד על הצלחת אתחול.

בדיקת GDB משתמשת בפורט loopback פנוי ושומרת `build/gdb.log` וכן
`build/gdb-qemu.stderr.log`. היא מוגבלת בזמן ומנקה את תהליך QEMU גם בכשל.
סביבת sandbox שחוסמת sockets מקומיים צריכה לאפשר את ההרצה הזאת.

לדיבוג ידני, בשני מסופים:

```sh
# Terminal 1
make debug
# Terminal 2, from the repository root
gdb -x debug.gdb
```

GDB יעצור בכניסה ל־C ויציג את הרגיסטרים ואת ההוראות הבאות. פקודת
`continue` תאפשר לקרנל להדפיס. `hbreak` מאפשר להציב breakpoint עוד לפני
שהקושחה טוענת את הקרנל לזיכרון.

## מסלול האתחול

1. QEMU טוען את `kernel.bin` דרך `-kernel`. בתחילתו כותרת Multiboot v1
   עם הדגל `0x10000` ושדות כתובת מפורשים: טעינה ב־`0x100000`, סוף התוכן,
   סוף BSS וכתובת הכניסה. זוהי תמונה גולמית לטעינה ישירה; היא אינה ISO
   או תמונת דיסק. התאימות לטעינה הזאת אומתה בפועל ב־QEMU.
2. `src/boot.S` מתחיל ב־32 ביט עם פסיקות כבויות, טוען GDT וסגמנטים
   שטוחים, מאפס BSS ומגדיר מחסנית. `linker.ld` קובע את כל הכתובות
   ואת נקודת הכניסה במפורש.
3. הקוד מקים טבלאות דפים בזיכרון המאופס וממפה את הג׳יגה הראשון בזהות,
   בדפים של 2 MiB. לאחר הפעלת PAE, טעינת CR3, הגדרת EFER.LME והפעלת
   paging, קפיצה רחוקה בוחרת סגמנט קוד של 64 ביט.
4. מוגדרת מחסנית בגודל 16 KiB המיושרת לפי ABI, ונקרא `kernel_main`.
   הקוד ב־C מאתחל UART מסוג 16550 ב־COM1 ל־115200 baud ומדפיס את הסמן.
   אחר כך המעבד ממתין עם פסיקות כבויות, עד למימוש IDT וחריגות.

היעד הראשוני הוא CPU יחיד מדגם QEMU `qemu64`, עם long mode,‏ PAE
ודפים גדולים זמינים. אין כרגע גילוי יכולות CPUID או הבטחה לאתחול על
חומרה שרירותית. מידע האתחול של Multiboot עדיין אינו נצרך.

הבנייה היא freestanding, ללא libc,‏ PIE,‏ stack protector או red zone.
`-mgeneral-regs-only` מונע שימוש אוטומטי ב־SIMD/נקודה צפה לפני אתחול מצב
המעבד המתאים. QEMU רץ ב־TCG, עם רשת כבויה, ללא חיבור דיסקים או תיקיות
מהמארח. אין צורך ב־KVM.

הראיות להרצה והצעד הבא מופיעים ב־[PROGRESS.md](PROGRESS.md).
