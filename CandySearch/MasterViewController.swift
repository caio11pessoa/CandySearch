/// Copyright (c) 2019 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit

class MasterViewController: UIViewController {
  @IBOutlet var tableView: UITableView!
  @IBOutlet var searchFooter: SearchFooter!
  @IBOutlet var searchFooterBottomConstraint: NSLayoutConstraint!
  
  var filteredCandies: [Candy] = []
  
  
  var candies: [Candy] = []
  
  let searchController = UISearchController(searchResultsController: nil)
  
  
  // returns true if the text typed in the search bar is empty, otherwise, it returns false.
  var isSearchBarEmpty: Bool {
    return searchController.searchBar.text?.isEmpty ?? true
  }
  
  var isFiltering: Bool {
    let searchBarScopeIsFiltering = searchController.searchBar.selectedScopeButtonIndex != 0
    return searchController.isActive &&  (!isSearchBarEmpty || searchBarScopeIsFiltering)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    candies = Candy.candies()
    
    
    // is a property on UISearchController that conforms to the new protocol, UISearchResultsUpdating.
    // With this protocol, UISearchResultsUpdating will informyour class of any text changes within the UISearchBar
    searchController.searchResultsUpdater = self
    
    // By default, UISearchController obscures the view controller containing the information you're searching.
    // This is useful if you're using another view controller for your searchResultsController.
    // In this instance, you've set the current view to show the results, so you don't want to obscure your view.
    searchController.obscuresBackgroundDuringPresentation = false
    
    // set the placeholder
    searchController.searchBar.placeholder = "Search Candies"
    
    // you add the searchBar to the navigationItem.
    // This is necessary because interface builder is not yet compatible with UISearchController.
    navigationItem.searchController = searchController
    
    // You ensure that the search bar doesn't remain on the screen if the user navigates to another view controller while the UISearchController is active.
    definesPresentationContext = true
    
    searchController.searchBar.scopeButtonTitles = Candy.Category.allCases.map { $0.rawValue }
    searchController.searchBar.delegate = self
    /*
     let notificationCenter = NotificationCenter.default
     notificationCenter.addObserver(
     forName: UIResponder.keyboardWillChangeFrameNotification,
     object: nil, queue: .main) { (notification) in
     self.handleKeyboard(notification: notification)
     }
     notificationCenter.addObserver(
     forName: UIResponder.keyboardWillHideNotification,
     object: nil, queue: .main) { (notification) in
     self.handleKeyboard(notification: notification)
     }
     
     */
    
    let notificationCenter = NotificationCenter.default
    notificationCenter.addObserver(
      forName: UIResponder.keyboardWillChangeFrameNotification,
      object: nil, queue: .main) { (notification) in
        self.handleKeyboard(notification: notification)
      }
    
    notificationCenter.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { (notification) in
      self.handleKeyboard(notification: notification)
      
    }
    
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    if let indexPath = tableView.indexPathForSelectedRow {
      tableView.deselectRow(at: indexPath, animated: true)
    }
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    guard
      segue.identifier == "ShowDetailSegue",
      let indexPath = tableView.indexPathForSelectedRow,
      let detailViewController = segue.destination as? DetailViewController
    else {
      return
    }
    
    let candy: Candy
    if isFiltering {
      candy = filteredCandies[indexPath.row]
    } else {
      candy = candies[indexPath.row]
    }
    detailViewController.candy = candy
  }
  
  func filterContentForSearchText(_ searchText: String, category: Candy.Category? = nil){
    filteredCandies = candies.filter { (candy: Candy) -> Bool in
      let doesCategoryMatch = category == .all || candy.category == category
      
      if isSearchBarEmpty {
        return doesCategoryMatch
      } else {
        return doesCategoryMatch && candy.name.lowercased().contains(searchText.lowercased())
      }
    }
    tableView.reloadData()
  }
  
  func handleKeyboard(notification: Notification) {
    // You first check if the notification is has anything to do with hiding the keyboard. If not, you move the search footer down and bail out.
    guard notification.name == UIResponder.keyboardWillChangeFrameNotification else {
      searchFooterBottomConstraint.constant = 0
      view.layoutIfNeeded()
      return
    }
    guard
      let info = notification.userInfo,
      let keyBoardFrame = info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
    else {
      return
    }
    
    // If the notification identifies the ending frame rectangle of the keyboard, you move the search footer just above the keyboard itself.
    let keyboardHeight = keyBoardFrame.cgRectValue.size.height
    UIView.animate(withDuration: 0.1, animations: { () -> Void in
      self.searchFooterBottomConstraint.constant = keyboardHeight
      self.view.layoutIfNeeded()

    })
  }
  
}

extension MasterViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView,
                 numberOfRowsInSection section: Int) -> Int {
    if(isFiltering) {
      searchFooter.setIsFilteringToShow(filteredItemCount: filteredCandies.count, of: candies.count)
      return filteredCandies.count
    }
    
    searchFooter.setNotFiltering()
    return candies.count
  }
  
  func tableView(_ tableView: UITableView,
                 cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell",
                                             for: indexPath)
    let candy: Candy
    if isFiltering {
      candy = filteredCandies[indexPath.row]
    }else {
      candy = candies[indexPath.row]
    }
    cell.textLabel?.text = candy.name
    cell.detailTextLabel?.text = candy.category.rawValue
    return cell
  }
}

extension MasterViewController: UISearchResultsUpdating {
  func updateSearchResults(for searchController: UISearchController) {
    let searchBar = searchController.searchBar
    let category = Candy.Category(rawValue: searchBar.scopeButtonTitles![searchBar.selectedScopeButtonIndex])
    filterContentForSearchText(searchBar.text!, category: category)
  }
}

extension MasterViewController: UISearchBarDelegate {
  func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
    let category = Candy.Category(rawValue: searchBar.scopeButtonTitles![selectedScope])
    filterContentForSearchText(searchBar.text!, category: category)
  }
}
