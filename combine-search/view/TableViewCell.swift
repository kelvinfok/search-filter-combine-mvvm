//
//  TableViewCell.swift
//  combine-search
//
//  Created by Kelvin Fok on 23/3/23.
//

import UIKit

class MovieTableViewCell: UITableViewCell {

  @IBOutlet weak var movieImageView: UIImageView!
  @IBOutlet weak var titleLabel: UILabel!
  
  func configure(movie: Movie) {
    movieImageView.sd_setImage(with: URL(string: movie.poster))
    titleLabel.text = movie.title
  }
}
