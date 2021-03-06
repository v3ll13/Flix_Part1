//
//  NowPlayingViewController.swift
//  
//
//  Created by MacBookPro9 on 9/17/18.
//

import UIKit
import AlamofireImage
import Foundation
import SystemConfiguration

class NowPlayingViewController: UIViewController , UITableViewDataSource, UISearchBarDelegate {
    
    
    //---------------Declaring variables and outlets-----------------
   
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var acIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var movieTableView: UITableView!
    var movies: [[String: Any]] = [];
    var filteredMovies: [[String: Any]] = [];
    var refreshControl: UIRefreshControl!
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //----------refresh control instanciation----------
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(NowPlayingViewController.didPullToRefresh(_:)), for: .valueChanged)
        
        //inserting subviews
        movieTableView.insertSubview(refreshControl, at: 0)
        
        //---------Do any additional setup after loading the view---------
        movieTableView.dataSource = self
        movieTableView.rowHeight = 230
        movieTableView.estimatedRowHeight = 230
        movieTableView.sectionHeaderHeight = 0
        movieTableView.sectionFooterHeight = 0
        
        //-----------calling method fetchMoivies---------
        fetchMovies()
        
         //----------------Start the activity indicator------------
         acIndicatorView.startAnimating()
        
        //----call for the internet connection
        showAlert()
        
        //---------filtered data and searchbar-----
        searchBar.delegate = self
        
        

        
    }
    
    
    
    //-----------------------------------METHODS------------------------------------
    
    func isInternetAvailable() -> Bool
    {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        return (isReachable && !needsConnection)
    }
    
    func showAlert() {
        if !isInternetAvailable() {
            let alert = UIAlertController(title: "Cannot get movies", message: "The Internet connection appears to be offline.", preferredStyle: .alert)
            let action = UIAlertAction(title: "Dismiss", style: .default, handler: nil)
            alert.addAction(action)
            present(alert, animated: true, completion: nil)
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.searchBar.text!.isEmpty{
            return self.movies.count
        }else{
            return filteredMovies.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as! MovieCell
        let movie = movies[indexPath.row]
        let title = movie["title"] as! String
        let overview =  movie["overview"] as! String
        cell.title_Label.text = title
        cell.overviewLabel.text = overview
        
        
        //request the images
        let posterPathString = movie["poster_path"] as! String
        let baseURLString = "https://image.tmdb.org/t/p/w500"
        let posterURL = URL(string: baseURLString + posterPathString)!
        cell.posterImageView.af_setImage(withURL: posterURL)
        
        return cell
    }
    
    func fetchMovies(){
        
        //---Creating url---
        let url = URL(string: "https://api.themoviedb.org/3/movie/now_playing?api_key=a07e22bc18f5cb106bfe4cc1f83ad8ed")!
        //---creating a request---
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        
        //---coordonate task of network request
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
        
        //---creating a task to get the data---
        let task = session.dataTask(with: request) { (data, response, error) in
            
            // This will run when the network request returns
            if let error = error {
                
                print(error.localizedDescription)
            } else if let data = data {
                
                let dataDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
                
                
                // TODO: Get the array of movies
                let movies = dataDictionary["results"] as! [[String: Any]]
                self.movies = movies
                self.filteredMovies = self.movies
                
                
                //self.acIndicatorView.stopAnimating()
                
                // TODO: Store the movies in a property to use elsewhere
                
                // TODO: Reload your table view data
                self.movieTableView.reloadData()
                
                //-------------stop the refresh----------
                self.refreshControl.endRefreshing()
                
                //stop animating
                self.acIndicatorView?.stopAnimating()
                
            }
        }
        task.resume()
    }
    
    
    
    @objc func didPullToRefresh(_ refreshControl:  UIRefreshControl){
        fetchMovies()
        
    }
    
    
    
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredMovies = searchText.isEmpty ? movies : movies.filter{ (movie: [String: Any]) -> Bool in
            return (movie["title"] as! String).localizedCaseInsensitiveContains(searchText)
        }
        self.movieTableView.reloadData()
    }
    
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    //---------------------------------ENDofMETHODS------------------------------------------
    

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            let cell = sender as! UITableViewCell
            if let indexPath = movieTableView.indexPath(for: cell){
            let movie = movies[indexPath.row]
            let detailsViewController = segue.destination as! DetailsViewController
            detailsViewController.movie = movie
        
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

   

}
