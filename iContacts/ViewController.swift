//
//  ViewController.swift
//  iContacts
//
//  Created by Zhangali Pernebayev on 28.11.2022.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    var arrayOfContactGroup: [ContactGroup] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    let contactManager = ContactManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        tableView.register(UINib(nibName: "ContactTableViewCell", bundle: nil), forCellReuseIdentifier: ContactTableViewCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        reloadDataSource()
    }

    @IBAction func addButtonTapped(_ sender: Any) {
        showAddContactAlert()
    }
    
    @IBAction func segmentedControlValueChanged(_ sender: UISegmentedControl) {
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
            let firstName: String = alertController.textFields![0].text!
            let lastName: String = alertController.textFields![1].text!
            let phone: String = alertController.textFields![2].text!
            let contact = Contact(firstName: firstName, lastName: lastName, phone: phone)
            
            self.add(contact: contact)
        }
        alertController.addAction(addAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
    
    func add(contact: Contact) {
        contactManager.add(contact: contact)
        self.reloadDataSource()
    }
    
    func reloadDataSource() {
        var dictionary: [String: [Contact]] = [:]
        
        let allContacts = contactManager.getAllContacts()
        allContacts.forEach { contact in
            
            var key: String!
            if segmentedControl.selectedSegmentIndex == 0 {
                key = String(contact.firstName.first!)
            } else if segmentedControl.selectedSegmentIndex == 1 {
                key = String(contact.lastName.first!)
            }
            
            if var existingContacts = dictionary[key] {
                existingContacts.append(contact)
                dictionary[key] = existingContacts
            }else{
                dictionary[key] = [contact]
            }
        }
        
        var arrayOfcontactGroup: [ContactGroup] = []
        
        let alphabeticallyOrderedKeys: [String] = dictionary.keys.sorted { key1, key2 in
            return key1 < key2
        }
        alphabeticallyOrderedKeys.forEach { key in
            let contacts = dictionary[key]
            let contactGroup = ContactGroup(title: key, contacts: contacts!)
            arrayOfcontactGroup.append(contactGroup)
        }
        self.arrayOfContactGroup = arrayOfcontactGroup
    }
    
    func getContact(indexPath: IndexPath) -> Contact {
        let contactGroup = arrayOfContactGroup[indexPath.section]
        let contact = contactGroup.contacts[indexPath.row]
        return contact
    }
    
    func deleteContact(indexPath: IndexPath) {
        let deletedContact = arrayOfContactGroup[indexPath.section].contacts.remove(at: indexPath.row)
        
        if arrayOfContactGroup[indexPath.section].contacts.count < 1 {
            arrayOfContactGroup.remove(at: indexPath.section)
        }
        
        contactManager.delete(contactToDelete: deletedContact)
    }
}

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

struct ContactManager {
    
    let allContactsKey: String = "allContactsKey"
    let userDefaults: UserDefaults = UserDefaults.standard
    
    func getAllContacts() -> [Contact] {
        var allContacts: [Contact] = []
        
        if let data = userDefaults.object(forKey: allContactsKey) as? Data {
            
            do {
                
                let decoder = JSONDecoder()
                allContacts = try decoder.decode([Contact].self, from: data)
                
            } catch {
                print("could'n decode given data to [Contact] with error: \(error.localizedDescription)")
            }
        }
        
        return allContacts
    }
    
    func add(contact: Contact) {
        
        var allContacts = getAllContacts()
        allContacts.append(contact)
        
        save(allContacts: allContacts)
    }
    
    func edit(contactToEdit: Contact, editedContact: Contact) {
        var allContacts = getAllContacts()
        
        for index in 0..<allContacts.count {
            
            let contact = allContacts[index]
            
            if contact.firstName == contactToEdit.firstName && contact.lastName == contactToEdit.lastName && contact.phone == contactToEdit.phone {
                
                allContacts.remove(at: index)
                allContacts.insert(editedContact, at: index)
                break
            }
        }
        
        save(allContacts: allContacts)
    }
    
    func delete(contactToDelete: Contact) {
        var allContacts = getAllContacts()
        
        for index in 0..<allContacts.count {
            
            let contact = allContacts[index]
            
            if contact.firstName == contactToDelete.firstName && contact.lastName == contactToDelete.lastName && contact.phone == contactToDelete.phone {
                
                allContacts.remove(at: index)
                break
            }
        }
        
        save(allContacts: allContacts)
    }
    
    func save(allContacts: [Contact]) {
        
        do {
            
            let encoder = JSONEncoder()
            let encodedData = try encoder.encode(allContacts)
            userDefaults.set(encodedData, forKey: allContactsKey)
            
        } catch {
            print("Couldn't encode given [Userscore] into data with error: \(error.localizedDescription)")
        }
    }
}
