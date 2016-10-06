# AutoIt_ZebraTester
Zebra printer TCP test utility

![Screenshot](http://funkyimg.com/i/2hNXA.png)

Утилита для тестирования и работы с принтером этикеток Zebra, подключенным к локальной сети.

## Функциональные возможности
* Проверка доступности устройства (Ping)
* Отправка команды по протколу TCP
* Редактирование команды в редакторе
* Работа с файлами скриптов ZPL и TXT
* Работа с быстрыми шаблонами
* Выбор темы оформления для редактора

## Реализация
### Среда разработки
Для разработки инструмента был использован интерпретатор [AutoIt Script v.3.3.14.2](https://www.autoitscript.com/site/)  
Дополнительно использовались Comunity UDF:
* [RSZ.au3](https://autoit-script.ru/index.php?topic=11231.0) - Библиотека изменения элементов GUI для _GUICtrl 
* [ExtMsgBox.au3](https://www.autoitscript.com/forum/topic/109096-extended-message-box-bugfix-version-9-aug-16/) - Библиотека расширенных свойств модального окна MsgBox 
   * StringSize.au3 - В составе ExtMsgBox.au3
* [DBug.au3](https://www.autoitscript.com/forum/topic/103142-another-debugger-for-autoit/) - Графический отладчик скриптов au3 

### База данных
В качестве базы данных используется файл ZebraTester.sqlite следующей структуры:

Таблица **Settings**  
*Предназначена для сохранения настроек пользователя.*

| Поле  | Описание            | Тип данных | Ограничения      |
| ------|:-------------------:| :--------- |:----------------:|
| ID    | ROWID идентификатор | INTEGER    | PRIMARY KEY      |
| Name  | Название настройки  | VARCHAR(64)| UNIQUE, NOT NULL |
| Value | Значение            | VARCHAR(32)|                  |

Версия 0.8 позволяет сохранять настройки:

1. **Last_IPAddress** - последний введенный IP адрес принтера 
2. **Last_Port** - последний введенный адрес порта 
3. **Last_Theme** - последняя выбранная пользователем тема редактора 

Таблица **Templates**  
*Предназначена для хранения шаблонов быстрых команд*

| Поле    | Описание            | Тип данных | Ограничения      |
| --------|:-------------------:| :--------- |:----------------:|
| ID      | ROWID идентификатор | INTEGER    | PRIMARY KEY      |
| Name    | Название шаблона    | VARCHAR(64)| UNIQUE, NOT NULL |
| Content | Текст шаблона       | BLOB       | NOT NULL         |
| Type    | Тип шаблона         | INTEGER(1) | Type IN (1, 2)   |

Версия 0.8 использует следующие типы шаблонов: 

**1**. Системный шаблон  
**2**. Пользовательский шаблон  

Системные шаблоны недоступны для изменения и удаления с помощью GUI инструментов ZebraTester.  
Для корректной работы с базой данных необходимо наличие файла sqlite3.dll. 
Для прямого взаимодействия с БД необходимо использовать инструмент Command Line Shell for SQLite https://sqlite.org/cli.html

### Компиляция приложения
С помощью утилиты AutoIt2Exe возможна компиляция сценария в исполняемый файл.  
При этом для его корректной работы потребуются следующие файлы в рабочем каталоге приложения:  
* sqlite3.dll
* ZebraTester.sqlite

## Обратная связь
Mail - dmitry.burnyshev@gmail.com  
Skype - diburn  
LinkedIn - https://www.linkedin.com/in/dmitry-burnyshev-348765b7