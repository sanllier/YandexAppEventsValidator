# YandexAppEventsValidator
YandexAppEventsValidator является client-side частью проекта [Нестор](https://wiki.yandex-team.ru/maps/mobile/analytics/docs/events-testing/).
[Нестор](https://wiki.yandex-team.ru/maps/mobile/analytics/docs/events-testing/) - это инструмент для тестирования логирования событий Мобильный Метрики. Ошибки и поломки в логировании событий на практике не редкость, а проверять это не так то просто: ручная проверка неэффективная, юнит тесты не помогут, UI тесты пока трудозатратны. Поэтому мы создали [Нестор](https://wiki.yandex-team.ru/maps/mobile/analytics/docs/events-testing/), который позволит сделать логи надежными, а аналитику приложения качественнее.

## Быстрый старт
1) Подключите YandexAppEventsValidator к своему проекту:
	* cocoapods (pod 'YandexAppEventsValidator', :git => 'https://github.com/sanllier/YandexAppEventsValidator.git') 
	* напрямую скопировав файлы из /YandexAppEventsValidator к себе
2) Реализуйте AEVControllerEventLogger и прокиньте события в метрику
3) Изучите [wiki](https://wiki.yandex-team.ru/maps/mobile/analytics/docs/events-testing/) и настройте server-side

# Docs
Основной компонент - _`AEVController`_. Для начала работы достаточно создать экземпляр объекта данного класса, передав ему uuid.

* _`init(uuid: String, testCaseIdentifierPreset: String = "", eventsLogger: AEVControllerEventLogger)`_

`uuid` - уникальный идентификатор пользователя
`testCaseIdentifierPreset` - префикс имени тест-кейса. Автоматически подставляется в поле ввода, для удобства задания имени тест-кейса
`eventsLogger` - логгер событий _`AEVController`_. Необходимо прокидывать все события в метрику

* _`convenience init(uuid: String, testCaseIdentifierPreset: String = "", 
					  validationURL: URL, validationToken: String,
					  eventsLogger: AEVControllerEventLogger)`_

`validationURL` - url, по которому будет передан запрос на сервер валидации
`validationToken` - токен, передаваемый в запрос к серверу валидации

---

Для контроля текущего состояния _`AEVController`_ неободимо реализовать _`AEVControllerListener`_ и подписаться на обновления через:
* _`addListener(_ listener: AEVControllerListener)`_
* _`removeListener(_ listener: AEVControllerListener)`_
Это может быть использовано для обновления состояния UI.

---

Тест-кейс считается начатым после вызова метода:
* _`start(testCase: String)`_ - немедленное начало тест-кейса
* _`startWithAlertPrompt`_ - показ предложения ввести имя текст-кейса

---

Вызов _`stopWithAlertPrompt`_ отобразит алерт с предложением закончить тест-кейс одним из возможных способов:
* __Copy Info__ - скопирует информацию о тест-кейсе в UIPasteboard и отправит событие об окончании тест-кейса
* __Validate__ - передаст запрос на сервер валидации и отправит событие об окончании тест-кейса

---

Имеется возможность создавать свои варианты окончания тест-кейса. Для этого необходимо зарегистрировать объект _`AEVAction`_ через вызов _`addValidatingAction(_ action: AEVAction)`_.

---

Фреймворк предоставляет базовую реализацию UI для отображения текущего состояния системы.
Для добавления UI элементов необходимо инстанцировать объект класса _`AEVStatusBarView`_, что приведет к отрисовке красного статус-бара в переданном контейнере во время запущенного тест-кейса.
