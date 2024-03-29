//
//  ViewController.swift
//  iContacts
//
//  Created by Zhangali Pernebayev on 28.11.2022.
//

import UIKit

class ViewController: UIViewController {

    // Ccылки на UI объект в InterFace Builder
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    /// Массив из структуры ContactGroup. Используется для хранения контактов в группе из первых букв Имени/Фамилии
    var arrayOfContactGroup: [ContactGroup] = [] {
        
        // didSet срабатывает каждый раз когда значение массива меняется. Например когда: добавляется, удаляется или вообще переписывается весь объект
        didSet {
            // Метод reloadData() у объекта UITableView используется для обновления интерфейса Таблицы.
            tableView.reloadData()
        }
    }
    
    /// Объект от структуры ContactManager
    let contactManager = ContactManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Регистрация собственного типа UITableViewCell, чей интерфейс построен с помощью .xib
        tableView.register(UINib(nibName: "ContactTableViewCell", bundle: nil), forCellReuseIdentifier: ContactTableViewCell.identifier)
        // Подписка на dataSource для обвновления данных
        tableView.dataSource = self
        // Подписка на delegate для управления действиями, шапкой, футером
        tableView.delegate = self
        
        // Инициализация объекта UIRefreshControl для отображения индикатора загрузки
        tableView.refreshControl = UIRefreshControl()
        // Таким образом отслеживается активация индикатора и вызывается метод reloadDataSource()
        tableView.refreshControl!.addTarget(self, action: #selector(reloadDataSource), for: .valueChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Перезагружаем данные каждый раз при новом отображении View. Например: когда возвращаемся назад
        reloadDataSource()
    }

    /// Обнаружение нажатия кнопки add
    @IBAction func addButtonTapped(_ sender: Any) {
        showAddContactAlert()
    }
    
    /// Обнаружение изменения выбранного сегмента, а именно типа сортировки
    @IBAction func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        // Идет запрос на обновление данных по выбранному типа сортировки
        reloadDataSource()
    }
    
    func showAddContactAlert() {
        let alertController = UIAlertController(title: "Add Contact", message: nil, preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "First name"
        }
        alertController.addTextField { textField in
            textField.placeholder = "Last name"
        }
        alertController.addTextField { textField in
            textField.placeholder = "Phone"
        }
        
        let addAction = UIAlertAction(title: "Add", style: .default) { _ in
            guard let firstName: String = alertController.textFields![0].text, !firstName.isEmpty else {
                self.showErrorAlert(message: "First name is empty")
                return
            }
            guard let lastName: String = alertController.textFields![1].text, !lastName.isEmpty else {
                self.showErrorAlert(message: "Last name is empty")
                return
            }
            guard let phone: String = alertController.textFields![2].text, !phone.isEmpty else {
                self.showErrorAlert(message: "Phone is empty")
                return
            }
            guard phone.isValidPhoneNumber() else {
                self.showErrorAlert(message: "Phone number is invalid")
                return
            }
            
            let contact = Contact(firstName: firstName, lastName: lastName, phone: phone)
            self.add(contact: contact)
        }
        alertController.addAction(addAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
    
    func showErrorAlert(message: String) {
        let errorAlertController = UIAlertController(title: "Error:", message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "Okay", style: .default)
        errorAlertController.addAction(okAction)
        
        present(errorAlertController, animated: true)
    }
    
    func add(contact: Contact) {
        contactManager.add(contact: contact)
        self.reloadDataSource()
    }
    
    /// Активирует индикатор загрузки, извлекает сохраненные контакты, деактивирует индикатор загрузки и переобозначает массив arrayOfContactGroup
    @objc
    func reloadDataSource() {
        // Начало анимации
        tableView.refreshControl!.beginRefreshing()
        
        // Создаем словарь, чтобы сюда положить разбить все контакты по первой букве Имени/Фамилии. Почему словарь? Потому что словарь обеспечивает уникальность ключей.
        var dictionary: [String: [Contact]] = [:]
        
        // С помощью ContactManager вытаскиваем все контакты из базы данных
        let allContacts = contactManager.getAllContacts()
        // Пробегаемся по каждому контакту в массиве
        allContacts.forEach { contact in
            
            var key: String!
            
            // С помощью условной конструкции определяем выбранный тип сортировки и обозначаем соответствующее значение для key
            if segmentedControl.selectedSegmentIndex == 0 {
                // Извлекаем первую букву Имени чей тип данных Char. После преображаем букву (Char) в другой тип данных String и передаем в key
                key = String(contact.firstName.first!)
            } else if segmentedControl.selectedSegmentIndex == 1 {
                // Извлекаем первую букву Фамилии чей тип данных Char. После преображаем букву (Char) в другой тип данных String и передаем в key
                key = String(contact.lastName.first!)
            }
            
            // Перед тем как установить значение для выбранного key нужно сначала проверить есть ли значение. Если есть, то добавить в существующий массив и переопределить значение для выбранного ключа.
            if var existingContacts = dictionary[key] {
                // Этот блок кода срабатывает если у словаря dictionary есть значение под ключем key
                // контакт добавляется уже в существующий массив
                existingContacts.append(contact)
                // Переопределяется значение для ключа key
                dictionary[key] = existingContacts
            }else{
                // Этот блок кода срабатывает если у словаря dictionary НЕТ значение под ключем key
                // Создается новое ключ-значение
                dictionary[key] = [contact]
            }
        }
        
        // Создается переменная типа данных массив из ContactGroup.
        var arrayOfcontactGroup: [ContactGroup] = []
        
        // Извлекаются отсортированные по алфавиту ключи из словаря dictionary и передаются в константу alphabeticallyOrderedKeys
        let alphabeticallyOrderedKeys: [String] = dictionary.keys.sorted { key1, key2 in
            return key1 < key2
        }
        // Пробегается по каждому ключу в массиве
        alphabeticallyOrderedKeys.forEach { key in
            // Извлекается контакт под ключем
            let contacts = dictionary[key]
            // Создается объект от структуры ContactGroup. Такой метод передачи данных называется иньекцией (Injection), когда значения передаются с помощью конструктора.
            let contactGroup = ContactGroup(title: key, contacts: contacts!)
            // Константа contactGroup добавляется в массив arrayOfcontactGroup
            arrayOfcontactGroup.append(contactGroup)
        }
        
        // Таким образом мы привели массив из Contact в форму массива из ContactGroup, чтобы отображать разбить контакты на секции для отображения.
        // 1. Разбили все контакты по группам из первой буквы Имени/Фамилии и получили словарь [String: [Contact]]
        // 2. Перенесли контакты в массив по алфавитному порядку
        
        tableView.refreshControl!.endRefreshing()
        self.arrayOfContactGroup = arrayOfcontactGroup
    }
    
    // Извлечение контакта из массива arrayOfContactGroup
    func getContact(indexPath: IndexPath) -> Contact {
        let contactGroup = arrayOfContactGroup[indexPath.section]
        let contact = contactGroup.contacts[indexPath.row]
        return contact
    }
    
    /// Удаляет ячейку с выбранным IndexPath и контакт из базы данных
    func deleteContact(indexPath: IndexPath) {
        
        // Удаление и присвоение удаленного объекта в константу deletedContact
        // Как это работает?
        //   1. Извлекается ContactGroup с указанной секцией из массива arrayOfContactGroup
        //   2. Идет обращение к атрибуту contacts у извлеченного ContactGroup
        //   3. Вызывается метод remove(at: indexPath.row) у массива из Contact, где передается индекс. Таким образом удаляется выбранный контакт и присаевается к константе deletedContact
        let deletedContact = arrayOfContactGroup[indexPath.section].contacts.remove(at: indexPath.row)
        
        // Если количество контактов в секции удаленного контакта меньше одного, то данная секция, а имеено ContactGroup удаляется из массива arrayOfContactGroup
        if arrayOfContactGroup[indexPath.section].contacts.count < 1 {
            
            // Удаление объекта ContactGroup из массива arrayOfContactGroup
            arrayOfContactGroup.remove(at: indexPath.section)
        }
        
        // Здесь уже идет удаление контакта из базы данных
        contactManager.delete(contactToDelete: deletedContact)
    }
}

// Расширение для ViewController и подписка на протокол UITableViewDataSource
extension ViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return arrayOfContactGroup.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrayOfContactGroup[section].contacts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ContactTableViewCell.identifier, for: indexPath) as! ContactTableViewCell
        let contact = getContact(indexPath: indexPath)
        
        if segmentedControl.selectedSegmentIndex == 0 {
            cell.titleLabel.text = "\(contact.firstName) \(contact.lastName)"
        }else if segmentedControl.selectedSegmentIndex == 1 {
            cell.titleLabel.text = "\(contact.lastName) \(contact.firstName)"
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return arrayOfContactGroup[section].title
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteContact(indexPath: indexPath)
        }
    }
}

// Расширение для ViewController и подписка на протокол UITableViewDelegate
extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let contact = getContact(indexPath: indexPath)
        let contactViewController = ContactViewController()
        contactViewController.contact = contact
        navigationController?.pushViewController(contactViewController, animated: true)
    }
}

struct Contact: Codable {
    let firstName: String
    let lastName: String
    let phone: String
}

struct ContactGroup {
    let title: String
    var contacts: [Contact]
}


// Создаем РАСШИРЕНИЕ для типа данных String и добавляем функцию
extension String {
    
    // Возвращает 'true' если номер телефона валидный, 'false' в ином случае
    func isValidPhoneNumber() -> Bool {
        
        let regEx = "^\\+(?:[0-9]?){6,14}[0-9]$"
        let phoneCheck = NSPredicate(format: "SELF MATCHES[c] %@", regEx)
        
        return phoneCheck.evaluate(with: self)
    }
}
