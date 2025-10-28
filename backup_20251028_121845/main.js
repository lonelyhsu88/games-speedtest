/* eslint-disable consistent-return */
/* eslint-disable no-plusplus */
/* eslint-disable @typescript-eslint/no-unused-expressions */
/* eslint-disable @typescript-eslint/no-unsafe-call */
/* eslint-disable @typescript-eslint/restrict-plus-operands */
/* eslint-disable @typescript-eslint/no-unsafe-argument */
/* eslint-disable @typescript-eslint/no-unsafe-member-access */
/* eslint-disable */
/* eslint-disable @typescript-eslint/no-magic-numbers */

/* eslint-disable @typescript-eslint/no-unsafe-assignment */
window.boot = () => {
  const settings = window._CCSettings;
  window._CCSettings = undefined;
  const onProgress = null;

  const RESOURCES = cc.AssetManager.BuiltinBundleName.RESOURCES;
  const INTERNAL = cc.AssetManager.BuiltinBundleName.INTERNAL;
  const MAIN = cc.AssetManager.BuiltinBundleName.MAIN;

  // const loadConfig = () => {
  //   return new Promise((resolve, reject) => {
  //     cc.resources.load("Config", cc.Prefab, (err, _Prefab) => {
  //       if (err) {
  //         reject(err);
  //       }
  //       resolve(_Prefab);
  //     });
  //   });
  // };

  // const loadI18nLaunch = () => {
  //   return new Promise((resolve, reject) => {
  //     cc.resources.load("i18nLaunch", cc.Prefab, (err, _Prefab) => {
  //       if (err) {
  //         reject(err);
  //       }
  //       resolve(_Prefab);
  //     });
  //   });
  // };

  const onStart = () => {
    cc.view.enableRetina(true);
    cc.view.resizeWithBrowserSize(true);

    if (cc.sys.isMobile) {
      if (settings.orientation === "landscape") {
        cc.view.setOrientation(cc.macro.ORIENTATION_LANDSCAPE);
      } else if (settings.orientation === "portrait") {
        cc.view.setOrientation(cc.macro.ORIENTATION_PORTRAIT);
      }
      // cc.view.enableAutoFullScreen(
      //   [
      //     cc.sys.BROWSER_TYPE_BAIDU,
      //     cc.sys.BROWSER_TYPE_BAIDU_APP,
      //     cc.sys.BROWSER_TYPE_WECHAT,
      //     cc.sys.BROWSER_TYPE_MOBILE_QQ,
      //     cc.sys.BROWSER_TYPE_MIUI,
      //     cc.sys.BROWSER_TYPE_HUAWEI,
      //     cc.sys.BROWSER_TYPE_UC
      //   ].indexOf(cc.sys.browserType) < 0
      // );
    }

    // Limit downloading max concurrent task to 2,
    // more tasks simultaneously may cause performance draw back on some android system / browsers.
    // You can adjust the number based on your own test result, you have to set it before any loading process to take effect.
    if (cc.sys.isBrowser && cc.sys.os === cc.sys.OS_ANDROID) {
      cc.assetManager.downloader.maxConcurrency = 2;
      cc.assetManager.downloader.maxRequestsPerFrame = 2;
    }

    const launchScene = settings.launchScene;
    //const bundle = cc.assetManager.bundles.find((b) => b.getSceneInfo(launchScene));

    cc.director.loadScene(launchScene);
    //const loadingScene = new cc.Scene();

    // // add canvas
    // const root = new cc.Node();
    // root.name = "Canvas";
    // root.parent = loadingScene;
    // const canvas = root.addComponent(cc.Canvas);
    // canvas.fitHeight = true;
    // canvas.fitWidth = true;
    // canvas.designResolution = new cc.Size(1280, 720, 0);

    // loadConfig().then(async (configPrefab) => {
    //   const configNode = cc.instantiate(configPrefab);
    //   cc.director.getScene().addChild(configNode);
    //   const configControl = configNode.getComponent("ConfigControl");
    //   configControl.loadConfig();
    //   await configControl.loadExternalConfig();
    //   const i18nLaunchPrefab = await loadI18nLaunch();
    //   const i18nLaunchNode = cc.instantiate(i18nLaunchPrefab);
    //   cc.director.getScene().addChild(i18nLaunchNode);

    //   cc.resources.load("guildTutorial", cc.Prefab, (err, _Prefab) => {
    //     if (err) {
    //       console.error("spawn prefab failed = ", err);
    //     } else {
    //       //console.log("spawn prefab successed", _Prefab);

    //       const _Node_GuildTutorial = cc.instantiate(_Prefab);
    //       _Node_GuildTutorial.name = "GuildTutorial";
    //       _Node_GuildTutorial.position = cc.v2(0, 0, 0);

    //       //教學頁要設成永久節點，必須為根節點，不能掛在Canvas底下
    //       cc.director.getScene().addChild(_Node_GuildTutorial, -1);

    //       //_Node_GuildTutorial.parent = root;
    //       //_Node_GuildTutorial.opacity = 100;
    //       //_Node_GuildTutorial.zIndex = -1;

    //       //console.log("node ", _Node_GuildTutorial);
    //     }
    //   });
    // });

    // // add background node (Adam 1120823 目前沒有打開)
    // const bgSpriteNode = new cc.Node();
    // bgSpriteNode.width = 1280;
    // bgSpriteNode.height = 720;
    // bgSpriteNode.position = cc.v2(0, 0, 0);
    // bgSpriteNode.parent = root;
    // bgSpriteNode.active = false;

    // // add background sprite
    // const bgSprite = bgSpriteNode.addComponent(cc.Sprite);
    // bgSprite.sizeMode = cc.Sprite.SizeMode.CUSTOM;
    // cc.resources.load("bg", cc.SpriteFrame, (err, spriteFrame) => {
    //   bgSprite.spriteFrame = spriteFrame;
    //   if (err) {
    //     console.log(err);
    //   }
    // });

    // const loadingPosition = cc.v2(0, -225, 0);
    // // add loading background
    // const loadingBgNode = new cc.Node();
    // loadingBgNode.width = 500;
    // loadingBgNode.height = 22;
    // loadingBgNode.parent = root;
    // loadingBgNode.position = loadingPosition;
    // const loadingBgSprite = loadingBgNode.addComponent(cc.Sprite);
    // loadingBgSprite.sizeMode = cc.Sprite.SizeMode.CUSTOM;
    // cc.resources.load("loadingBg", cc.SpriteFrame, (err, spriteFrame) => {
    //   loadingBgSprite.spriteFrame = spriteFrame;
    //   if (err) {
    //     console.log(err);
    //   }
    // });

    // // add loading bar
    // const loadingBarNode = new cc.Node();
    // const loadingBarNodeWidth = 490;
    // loadingBarNode.height = 16;
    // loadingBarNode.parent = root;
    // loadingBarNode.position = loadingPosition;
    // const loadingBarSprite = loadingBarNode.addComponent(cc.Sprite);
    // // loadingBarSprite.type = cc.Sprite.Type.FILLED;
    // // loadingBarSprite.fillType = cc.Sprite.FillType.HORIZONTAL;
    // // loadingBarSprite.fillStart = 0;
    // // loadingBarSprite.fillRange = 0;
    // loadingBarSprite.sizeMode = cc.Sprite.SizeMode.CUSTOM;
    // cc.resources.load("loadingBar", cc.SpriteFrame, (err, spriteFrame) => {
    //   loadingBarSprite.spriteFrame = spriteFrame;
    //   if (err) {
    //     console.log(err);
    //   }
    // });

    // loadingScene.loadinglaunchScene = (scene) => {
    //   const startTime = Date.now();
    //   cc.director.preloadScene(
    //     scene,
    //     (completedCount, totalCount, item) => {
    //       // console.log("cc.director.preloadScene", completedCount, totalCount, item);
    //       // const progress = completedCount / totalCount * 100;
    //       // console.log(`預先加載進度：${progress.toFixed(2)}%`);
    //       loadingBarNode.width = (completedCount / totalCount) * loadingBarNodeWidth;
    //       loadingBarNode.position = cc.v2(
    //         (completedCount / totalCount) * (loadingBarNodeWidth / 2) - loadingBarNodeWidth / 2,
    //         loadingPosition.y,
    //         0
    //       );
    //     },
    //     (error) => {
    //       if (error) {
    //         console.log("==preloadScene error==", scene, error);
    //         return;
    //       }
    //       const endTime = Date.now();
    //       const loadingTime = endTime - startTime;
    //       console.log(`預先加載時間：${loadingTime}毫秒`);

    //       //Loading完成，通知guildTutorial打開play按鈕
    //       cc.systemEvent.emit("loadingFinished");

    //       //隱藏loading bar跟label
    //       loadingBarNode.active = false;
    //       loadingBgNode.active = false;

    //       //Loading完直接跳轉場景到MainGame
    //       bundle.loadScene(scene, null, onProgress, (err, loadedScene) => {
    //         if (!err) {
    //           cc.director.runSceneImmediate(loadedScene);
    //           if (cc.sys.isBrowser) {
    //             // show canvas
    //             const gameCanvas = document.getElementById("GameCanvas");
    //             gameCanvas.style.visibility = "";
    //             const div = document.getElementById("GameDiv");
    //             if (div) {
    //               div.style.backgroundImage = "";
    //             }
    //             console.log("Success to load scene: " + scene);
    //           }
    //         }
    //       });
    //     }
    //   );
    // };

    // cc.director.runSceneImmediate(loadingScene);
    // loadingScene.loadinglaunchScene(launchScene);
  };

  const option = {
    id: "GameCanvas",
    debugMode: settings.debug ? cc.debug.DebugMode.INFO : cc.debug.DebugMode.ERROR,
    showFPS: settings.debug,
    frameRate: 60,
    groupList: settings.groupList,
    collisionMatrix: settings.collisionMatrix
  };

  cc.assetManager.init({
    bundleVers: settings.bundleVers,
    remoteBundles: settings.remoteBundles,
    server: settings.server
  });

  const bundleRoot = [INTERNAL];
  settings.hasResourcesBundle && bundleRoot.push(RESOURCES);

  let count = 0;
  function cb(err) {
    if (err) {
      return console.error(err.message, err.stack);
    }
    count++;
    if (count === bundleRoot.length + 1) {
      cc.assetManager.loadBundle(MAIN, (error) => {
        if (!error) {
          cc.game.run(option, onStart);
        }
      });
    }
  }

  cc.assetManager.loadScript(
    settings.jsList.map((x) => "src/" + x),
    cb
  );

  for (let i = 0; i < bundleRoot.length; i++) {
    cc.assetManager.loadBundle(bundleRoot[i], cb);
  }
};

if (window.jsb) {
  const isRuntime = typeof loadRuntime === "function";
  if (isRuntime) {
    require("src/settings.092d8.js");
    require("src/cocos2d-runtime.js");
    if (CC_PHYSICS_BUILTIN || CC_PHYSICS_CANNON) {
      require("src/physics.js");
    }
    require("jsb-adapter/engine/index.js");
  } else {
    require("src/settings.092d8.js");
    require("src/cocos2d-jsb.js");
    if (CC_PHYSICS_BUILTIN || CC_PHYSICS_CANNON) {
      require("src/physics.js");
    }
    require("jsb-adapter/jsb-engine.js");
  }

  cc.macro.CLEANUP_IMAGE_CACHE = true;
  window.boot();
}
