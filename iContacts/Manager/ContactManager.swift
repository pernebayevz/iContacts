//
//  ContactManager.swift
//  iContacts
//
//  Created by Zhangali Pernebayev on 15.12.2022.
//

import Foundation

/// Данная структура используется для управления данными контактов и не имеет ничего лишнего. Таким образом нужно упаковывать методы в одну структуру, чтобы их можно было переиспользовать в нескольких местах и избежать повторения кода.
struct ContactManager {
    
    /// Ключ под которым хранится массив контактов
    let allContactsKey: String = "allContactsKey"
    /// Таким образом выводим глобально стандартную базу, чтобы можно было переиспользовать в нескольких местах
    let userDefaults: UserDefaults = UserDefaults.standard
    
    /// Возвращает все данные из базы данных UserDefaults.standard
    func getAllContacts() -> [Contact] {
        
        // Сначала обявляется переменная с пустым массивом
        var allContacts: [Contact] = []
        
        // Проверяем есть ли объект типа данных Data под ключом allContactsKey.
        if let data = userDefaults.object(forKey: allContactsKey) as? Data {
            // Если есть значение и имеет преобразуемо в Data, то заходит в этом блок кода {}
            
            // Обвертываем в do так как метод decoder.decode([Contact].self, from: data) может выкинуть ошибку
            do {
                
                // Данный кусок кода используется для декодирования объекта типа данных Data в массив из Contact
                let decoder = JSONDecoder()
                allContacts = try decoder.decode([Contact].self, from: data)
                
            } catch {
                // Данный блок кода срабатывает только если метод encoder.encode(allContacts) выкинет ошибку
                // И чтобы словить эту ошибку используем CATCH и печатаем описание
                print("could'n decode given data to [Contact] with error: \(error.localizedDescription)")
            }
        }
        
        return allContacts
    }
    
    /// Принимает объект типа данных Contact и добавляет в базу данных UserDefaults.standard
    func add(contact: Contact) {
        
        // Но сначала извлекает все сохраненные контакты, так как значение переписывается
        var allContacts = getAllContacts()
        // Добавление нового контакта
        allContacts.append(contact)
        
        // сохранение контактов в базу данных
        save(allContacts: allContacts)
    }
    
    // Редактирование контакта
    func edit(contactToEdit: Contact, editedContact: Contact) {
        // Извлекаются все контакты
        var allContacts = getAllContacts()
        
        // Пробегаемся по каждому контакту
        for index in 0..<allContacts.count {
            // извлекаемся контакт по индексу
            let contact = allContacts[index]
            
            //Сверяем данные контакта
            if contact.firstName == contactToEdit.firstName && contact.lastName == contactToEdit.lastName && contact.phone == contactToEdit.phone {
                // Если они одинаковые то срабатывает данный блок кода
                
                // Удаляем из массива allContacts старый контакт по индексу
                allContacts.remove(at: index)
                // Добавляем новый, отредактрованный контакт в массив под индексом
                allContacts.insert(editedContact, at: index)
                
                // ключевое слово break выводит чтение кода из цикла. Почему именно здесь? Потому что здесь мы уже нашли нужный нам контакт и заменили на новый, и дальше нет смысла пробегаться по остальным контактам в массиве allContacts.
                break
            }
        }
        
        // Перезаписываемся список контактов в базу данных
        save(allContacts: allContacts)
    }
    
    // Удаление выбранного контакта
    func delete(contactToDelete: Contact) {
        // Извлекаются все контакты
        var allContacts = getAllContacts()
        
        // Пробегается по каждому контакту в allContacts
        for index in 0..<allContacts.count {
            
            // Извлечение контакта
            let contact = allContacts[index]
            
            //Сверяем данные контакта
            if contact.firstName == contactToDelete.firstName && contact.lastName == contactToDelete.lastName && contact.phone == contactToDelete.phone {
                // Если они одинаковые то срабатывает данный блок кода
                
                // Удаляется контакт с индексом
                allContacts.remove(at: index)
                
                // ключевое слово break выводит чтение кода из цикла. Почему именно здесь? Потому что здесь мы уже нашли нужный нам контакт и заменили на новый, и дальше нет смысла пробегаться по остальным контактам в массиве allContacts.
                break
            }
        }
        
        save(allContacts: allContacts)
    }
    
    /// Записывает массив из Contact в UserDefaults
    func save(allContacts: [Contact]) {
        
        // Обвертываем в do так как метод encoder.encode(allContacts) может выкинуть ошибку
        do {
            
            // Кодируем массив из Contact в тип данных Data
            let encoder = JSONEncoder()
            let encodedData = try encoder.encode(allContacts)
            
            // Записываем полученный Data в UserDefaults под ключом "allContactsKey"
            userDefaults.set(encodedData, forKey: allContactsKey)
            
        } catch {
            // Данный блок кода срабатывает только если метод encoder.encode(allContacts) выкинет ошибку
            print("Couldn't encode given [Userscore] into data with error: \(error.localizedDescription)")
        }
    }
}
