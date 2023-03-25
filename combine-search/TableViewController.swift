//
//  ViewController.swift
//  combine-search
//
//  Created by Kelvin Fok on 23/3/23.
//

import UIKit
import Combine
import SDWebImage

class SearchViewModel {
  
  struct Input {
    let viewDidLoadPublisher: AnyPublisher<Void, Never>
    let searchTextPublisher: AnyPublisher<String?, Never>
  }
  
  struct Output {
    let viewDidLoadPublisher: AnyPublisher<Void, Never>
    let searchTextPublisher: AnyPublisher<Void, Never>
    let setDataSourcePublisher: AnyPublisher<[Movie], Never>
  }
  
  @Published private var movies: [Movie] = []
  @Published private var searchText: String?
  
  func transform(input: Input) -> Output {
    
    let viewDidLoadPublisher: AnyPublisher<Void, Never> = input.viewDidLoadPublisher.handleEvents(receiveOutput: { [weak self] _ in
      self?.fetchMovies()
    }).flatMap {
      return Just(()).eraseToAnyPublisher()
    }.eraseToAnyPublisher()
    
    let searchTextPublisher: AnyPublisher<Void, Never> = input.searchTextPublisher.handleEvents(receiveOutput: { [weak self] searchText in
      self?.searchText = searchText
    }).flatMap { _ in
      return Just(()).eraseToAnyPublisher()
    }.eraseToAnyPublisher()
    
    let setDataSourcePublisher: AnyPublisher<[Movie], Never> = Publishers.CombineLatest(
      $movies.compactMap { $0 },
      $searchText).flatMap { (movies: [Movie], searchText: String?) in
        if let searchText = searchText, !searchText.isEmpty {
          let filtered = movies.filter { $0.title.lowercased().contains(searchText.lowercased()) }
          return Just(filtered).eraseToAnyPublisher()
        } else {
          return Just(movies).eraseToAnyPublisher()
        }
      }.eraseToAnyPublisher()
    
    return .init(viewDidLoadPublisher: viewDidLoadPublisher,
                 searchTextPublisher: searchTextPublisher,
                 setDataSourcePublisher: setDataSourcePublisher)
  }
  
  private func fetchMovies() {
    let group = DispatchGroup()
    var temp = [Movie]()
    for page in 1...10 {
      group.enter()
      var url: URL {
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name:"s", value: "marvel"),
            URLQueryItem(name:"apikey", value: "9f43a994"),
            URLQueryItem(name:"page", value: "\(page)")
        ]
        return URL(string: "https://www.omdbapi.com/" + components.string!)!
      }
      let request = URLRequest(url: url)
      URLSession.shared.dataTask(with: request) { data, res, err in
        let response = try! JSONDecoder().decode(MoviesResponse.self, from: data!)
        temp.append(contentsOf: response.result)
        group.leave()
      }.resume()
    }
    group.notify(queue: .main) {
      self.movies = temp
    }
  }
  
}

class SearchController: UITableViewController {
  
  private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
  private let searchTextSubject = PassthroughSubject<String?, Never>()

  private let viewModel = SearchViewModel()
  
  @Published private var filtered: [Movie] = []
  
  private lazy var searchController: UISearchController = {
    let controller = UISearchController(searchResultsController: nil)
    controller.searchResultsUpdater = self
    controller.obscuresBackgroundDuringPresentation = false
    controller.searchBar.placeholder = "Filter results"
    return controller
  }()
  
  private var cancellables = Set<AnyCancellable>()
  
  override func loadView() {
    super.loadView()
    observe()
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    viewDidLoadSubject.send()
    setupTableView()
    setupNavigation()
  }
  
  private func setupTableView() {
    tableView.contentInset = .init(top: -20, left: 0, bottom: 0, right: 0)
  }
  
  private func setupNavigation() {
    navigationItem.searchController = searchController
  }
  
  private func observe() {
    $filtered
      .receive(on: DispatchQueue.main)
      .sink { [weak self ] _ in
        self?.tableView.reloadData()
    }.store(in: &cancellables)
    
    
    let input = SearchViewModel.Input(
      viewDidLoadPublisher: viewDidLoadSubject.eraseToAnyPublisher(),
      searchTextPublisher: searchTextSubject.eraseToAnyPublisher())
    let output = viewModel.transform(input: input)
    
    [output.viewDidLoadPublisher, output.searchTextPublisher].forEach {
      $0.sink { _ in }.store(in: &cancellables)
    }
    
    output.setDataSourcePublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] movies in
      self?.filtered = movies
    }.store(in: &cancellables)
    
  }
}

extension SearchController {
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return filtered.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cellId", for: indexPath) as! MovieTableViewCell
    let movie = filtered[indexPath.item]
    cell.configure(movie: movie)
    return cell
  }
  
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 144
  }
  
  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return String(format: "%d results found", filtered.count)
  }
}

extension SearchController: UISearchResultsUpdating {
  func updateSearchResults(for searchController: UISearchController) {
    let searchText = searchController.searchBar.text
    searchTextSubject.send(searchText)
  }
}
