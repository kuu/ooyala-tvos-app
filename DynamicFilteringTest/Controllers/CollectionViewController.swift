//
//  CollectionViewController.swift
//  DynamicFilteringTest
//
//  Created by Kuu Miyazaki on 2018/03/15.
//  Copyright © 2018 Kuu Miyazaki. All rights reserved.
//

import UIKit

private let reuseIdentifier = "AssetCell"
private let detailSegueIdentifier = "DetailSegue"

class CollectionViewController: UICollectionViewController {
    
    var label: Label?
    var assets = [Asset]()

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.remembersLastFocusedIndexPath = true
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView?.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let detailViewController = segue.destination as? DetailViewController, let selectedIndex = collectionView?.indexPathsForSelectedItems?.first {
            detailViewController.asset = assets[selectedIndex.item]
        }
    }

}

// MARK: - UICollectionViewDataSource
extension CollectionViewController {
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! CollectionViewCell
        
        if assets.count > 0 {
            let asset = assets[indexPath.item]
            cell.assetTitle.text = asset.name
            cell.assetImage.image = asset.thumbnail
        }
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension CollectionViewController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: detailSegueIdentifier, sender: nil)
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        cell.alpha = 0.0
        UIView.animate(withDuration: 1.0) {
            cell.alpha = 1.0
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didUpdateFocusIn context: UICollectionViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if let nextFocusedView = context.nextFocusedView {
            collectionView.bringSubview(toFront: nextFocusedView)
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension CollectionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 500, height: 400)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(0, 90, 70, 90)
    }
}

// MARK: - LabelChangedDelegate
extension CollectionViewController: LabelChangedDelegate {
    func labelChanged(_ newLabel: Label) {
        label = newLabel
        AssetService.getAssets(for: label!, {assets in
            self.assets = assets
            self.collectionView?.reloadData()
        })
    }
}
