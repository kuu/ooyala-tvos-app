//
//  TableViewController.swift
//  DynamicFilteringTest
//
//  Created by Kuu Miyazaki on 2018/03/15.
//  Copyright © 2018 Kuu Miyazaki. All rights reserved.
//

import UIKit

protocol LabelChangedDelegate: class {
    func labelChanged(_ label: Label)
}

class TableViewController: UITableViewController {
    
    var labels = [Label]()
    weak var delegate: LabelChangedDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "reuseIdentifier")
        
        if let detailNav = splitViewController?.viewControllers.last as? UINavigationController, let labelDelegate = detailNav.topViewController as? LabelChangedDelegate {
            delegate = labelDelegate
        }
        
        AssetService.getLabels { labels in
            self.labels = labels
            self.tableView?.reloadData()
        }
        
        tableView.remembersLastFocusedIndexPath = true
    }
}

// MARK: - UITableViewDataSource
extension TableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return labels.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        if labels.count > 0 {
            cell.textLabel?.text = labels[indexPath.row].path
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Labels"
    }
}

// MARK: - UITableViewDelegate
extension TableViewController {
    override func tableView(_ tableView: UITableView, didUpdateFocusIn context: UITableViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        guard let indexPath = context.nextFocusedIndexPath else { return }
        delegate?.labelChanged(labels[(indexPath as NSIndexPath).row])
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let detailNav = splitViewController?.viewControllers.last as? UINavigationController {
            detailNav.popToRootViewController(animated: true)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
