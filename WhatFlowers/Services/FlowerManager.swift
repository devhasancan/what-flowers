import UIKit

protocol FlowerManagerDelegate: AnyObject {
    func didUpdateFlower(_ title: String, _ extract: String?, _ imageURL: String?)
    func didFailWithError(_ message: String)
}

struct FlowerManager {
    
    let wikipediaURL = "https://en.wikipedia.org/w/api.php?format=json&action=query&prop=extracts%7Cpageimages&pithumbsize=500&redirects=1&indexpageids&exintro=&explaintext="
    
    private static let wikipediaTitles = [
          "Globe-Flower": "Globeflower",
          "Giant White Arum Lily": "Zantedeschia aethiopica",
          "Pincushion Flower": "Scabiosa",
          "Prince Of Wales Feathers": "Amaranthus hypochondriacus",
          "Love In The Mist": "Nigella damascena",
          "Cape Flower": "Carpobrotus edulis",
          "Barbeton Daisy": "Gerbera jamesonii",
          "Orange Dahlia": "Dahlia",
          "Pink-Yellow Dahlia?": "Dahlia",
          "Thorn Apple": "Datura stramonium",
          "Toad Lily": "Tricyrtis",
          "Ball Moss": "Tillandsia recurvata",
          "Mexican Petunia": "Ruellia simplex"
      ]
    
    weak var delegate: FlowerManagerDelegate?
    
    func fetchFlower(flowerName: String) {
        let title = FlowerManager.wikipediaTitles[flowerName] ?? flowerName.lowercased()
        
        if let safeFlowerName = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            let urlString = "\(wikipediaURL)&titles=\(safeFlowerName)"
            performRequest(urlString: urlString)
        }
    }

    func performRequest(urlString: String) {
        guard let url = URL(string: urlString) else {
            delegate?.didFailWithError("Address could not be created.")
            return
        }
        
        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: url) { data, response, error in
            
            if let error = error {
                print(error)
                self.delegate?.didFailWithError("Connection could not be established. Check your internet connection.")
                return
            }
            
            guard let safeData = data, let flowerPage = self.parseJSON(safeData) else {
                self.delegate?.didFailWithError("Information could not be obtained.")
                return
            }
            
            self.delegate?.didUpdateFlower(flowerPage.title,
                                           flowerPage.extract,
                                           flowerPage.thumbnail?.source)
            }
            
        task.resume()
    }
    
    func parseJSON(_ flowerData: Data) -> Page? {
        
        let decoder = JSONDecoder()
        
        do {
            let decodedData = try decoder.decode(FlowerData.self, from: flowerData)
            let pageID = decodedData.query.pageids[0]
            let flowerPage = decodedData.query.pages[pageID]
            return flowerPage
        } catch {
            print(error)
            return nil
        }
    }
    

}
