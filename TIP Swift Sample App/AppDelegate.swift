//
//  AppDelegate.swift
//  TIP Swift Sample App
//
//  Created by Nolan O'Brien on 3/2/17.
//  Copyright © 2017 Twitter. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, TIPImagePipelineObserver, TIPLogger, TIPImageAdditionalCache, TwitterAPIDelegate {

    @objc public var window: UIWindow?
    @objc public var tabBarController: UITabBarController?
    @objc public var imagePipeline: TIPImagePipeline?

    @objc public var searchCount: UInt = 100
    @objc public var searchWebP: Bool = false
    @objc public var usePlaceholder: Bool = false

    @objc public var debugInfoVisible: Bool {
        get {
            return TIPImageViewFetchHelper.isDebugInfoVisible
        }
        set(visible) {
            TIPImageViewFetchHelper.isDebugInfoVisible = visible
        }
    }

    private var opCount: Int = 0
    private var placeholder: UIImage?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
    {
        let tipConfig = TIPGlobalConfiguration.sharedInstance()
        tipConfig.logger = self
        tipConfig.serializeCGContextAccess = true
        tipConfig.isClearMemoryCachesOnApplicationBackgroundEnabled = true
        tipConfig.add(self)

        let catalogue = TIPImageCodecCatalogue.sharedInstance()
        catalogue.setCodec(TIPXWebPCodec.init(), forImageType: TIPXImageTypeWebP)

        self.imagePipeline = TIPImagePipeline(identifier: "Twitter.Example")
        self.imagePipeline?.additionalCaches = [self]

        TwitterAPI.sharedInstance().delegate = self


        let lightBlueColor = UIColor.init(colorLiteralRed: 150.0/255.0, green: 215.0/255.0, blue: 1.0, alpha: 0.0)

        UISearchBar.appearance().barTintColor = lightBlueColor
        UISearchBar.appearance().tintColor = UIColor.white
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).tintColor = lightBlueColor
        UINavigationBar.appearance().barTintColor = lightBlueColor
        UINavigationBar.appearance().tintColor = UIColor.white
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        UITabBar.appearance().barTintColor = lightBlueColor
        UITabBar.appearance().tintColor = UIColor.white
        UISlider.appearance().minimumTrackTintColor = lightBlueColor
        UISlider.appearance().tintColor = lightBlueColor
        UIWindow.appearance().tintColor = lightBlueColor

        self.window = UIWindow.init(frame: UIScreen.main.bounds)

        let navCont1 = UINavigationController.init(rootViewController: TwitterSearchViewController.init())
        navCont1.tabBarItem = UITabBarItem.init(title: "Search", image: UIImage(named: "first"), tag: 1)
        let navCont2 = UINavigationController.init(rootViewController: SettingsViewController.init())
        navCont2.tabBarItem = UITabBarItem.init(title: "Settings", image: UIImage(named: "second"), tag: 2)
        let navCont3 = UINavigationController.init(rootViewController: InspectorViewController.init())
        navCont3.tabBarItem = UITabBarItem.init(title: "Inspector", image: UIImage(named: "first"), tag: 3)

        self.tabBarController = UITabBarController.init()
        self.tabBarController?.viewControllers = [ navCont1, navCont2, navCont3 ]

        self.window?.rootViewController = self.tabBarController
        self.window?.backgroundColor = UIColor.orange
        self.window?.makeKeyAndVisible()

        return true;
    }

    // MARK: public

    public func incrementNetworkOperations() -> Void
    {
        if (Thread.isMainThread) {
            self.incOps()
        } else {
            DispatchQueue.main.async {
                self.incOps()
            }
        }
    }

    public func decrementNetworkOperations() -> Void
    {
        if (Thread.isMainThread) {
            self.decOps()
        } else {
            DispatchQueue.main.async {
                self.decOps()
            }
        }
    }

    private func incOps() -> Void
    {
        self.opCount += 1
        if (self.opCount > 0) {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
    }

    private func decOps() -> Void
    {
        self.opCount -= 1
        if (self.opCount <= 0) {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }

    // MARK: API Delegate

    @objc func apiWorkStarted(_ api: TwitterAPI)
    {
        self.incrementNetworkOperations()
    }

    @objc func apiWorkFinished(_ api: TwitterAPI)
    {
        self.decrementNetworkOperations()
    }

    // MARK: Observer

    @objc func tip_imageFetchOperation(_ op: TIPImageFetchOperation, didStartDownloadingImageAt URL: URL)
    {
        self.incrementNetworkOperations()
    }

    @objc func tip_imageFetchOperation(_ op: TIPImageFetchOperation, didFinishDownloadingImageAt URL: URL, imageType type: String, sizeInBytes byteSize: UInt, dimensions: CGSize, wasResumed: Bool)
    {
        self.decrementNetworkOperations()
    }

    // MARK: Logger

    @objc func tip_log(with level: TIPLogLevel, file: String, function: String, line: Int32, message: String)
    {
        let levelString: String
        switch (level) {
            case .emergency:
                fallthrough
            case .alert:
                fallthrough
            case .critical:
                fallthrough
            case .error:
                levelString = "ERR"
                break
            case .warning:
                levelString = "WRN"
                break
            case .notice:
                fallthrough
            case .information:
                levelString = "INF"
                break
            case .debug:
                levelString = "DBG"
                break
        }

        print("[\(levelString): \(message)")
    }

    // MARK: Additional Cache

    @objc func tip_retrieveImage(for URL: URL, completion: @escaping TIPImageAdditionalCacheFetchCompletion)
    {
        var image: UIImage?
        let lastPathComponent: String? = URL.lastPathComponent
        if let scheme = URL.scheme, let host = URL.host, let lastPathComponent = lastPathComponent {
            if scheme == "placeholder" && host == "placeholder.com" && lastPathComponent == "placeholder.jpg" {
                if self.placeholder == nil {
                    self.placeholder = UIImage(named: "placeholder.jpg")
                }
                image = self.placeholder
            }
        }
        completion(image);
    }
}

func APP_DELEGATE() -> AppDelegate
{
    return UIApplication.shared.delegate as! AppDelegate
}
