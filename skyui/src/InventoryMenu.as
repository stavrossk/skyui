﻿import gfx.io.GameDelegate;
import Shared.GlobalFunc;
import gfx.ui.NavigationCode;

import skyui.InventoryColumnFormatter;
import skyui.InventoryDataFetcher;

class InventoryMenu extends ItemMenu
{
	private var _bMenuClosing:Boolean;

	var EquipButtonArt:Object;
	var AltButtonArt:Object;
	var ChargeButtonArt:Object;
	var PrevButtonArt:Object;
	var ItemCardListButtonArt:Array;
	var CategoryListIconArt:Array;
	
	var ColumnFormatter:InventoryColumnFormatter;
	var DataFetcher:InventoryDataFetcher;

	// ?
	var bPCControlsReady = true;
	
	
	function InventoryMenu()
	{
		super();
		
		_bMenuClosing = false;
		
		EquipButtonArt = {PCArt:"M1M2", XBoxArt:"360_LTRT", PS3Art:"PS3_LBRB"};
		AltButtonArt = {PCArt:"E", XBoxArt:"360_A", PS3Art:"PS3_A"};
		ChargeButtonArt = {PCArt:"T", XBoxArt:"360_RB", PS3Art:"PS3_RT"};
		ItemCardListButtonArt = [{PCArt:"Enter", XBoxArt:"360_A", PS3Art:"PS3_A"},
								 {PCArt:"Tab", XBoxArt:"360_B", PS3Art:"PS3_B"}];
		PrevButtonArt = undefined;
		
		CategoryListIconArt = ["cat_favorites", "inv_all", "inv_weapons", "inv_armor",
							   "inv_potions", "inv_scrolls", "inv_food", "inv_ingredients",
							   "inv_books", "inv_keys", "inv_misc"];
		
		ColumnFormatter = new InventoryColumnFormatter();
		ColumnFormatter.maxTextLength = 80;
		
		DataFetcher = new InventoryDataFetcher();
	}

	function InitExtensions()
	{
		super.InitExtensions();
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("InventoryMenu InitExtensions()");
		GlobalFunc.AddReverseFunctions();
		InventoryLists_mc.ZoomButtonHolderInstance.gotoAndStop(1);
		BottomBar_mc.SetButtonArt(ChargeButtonArt,3);

		InventoryLists_mc.CategoriesList.setIconArt(CategoryListIconArt);

		InventoryLists_mc.ItemsList.entryClassName = "ItemsListEntryInv";
		InventoryLists_mc.ItemsList.columnFormatter = ColumnFormatter;
		InventoryLists_mc.ItemsList.dataFetcher = DataFetcher;
		InventoryLists_mc.ItemsList.setConfigSection("ItemList");
		
		GameDelegate.addCallBack("AttemptEquip",this,"AttemptEquip");
		GameDelegate.addCallBack("DropItem",this,"DropItem");
		GameDelegate.addCallBack("AttemptChargeItem",this,"AttemptChargeItem");
		GameDelegate.addCallBack("ItemRotating",this,"ItemRotating");

		ItemCard_mc.addEventListener("itemPress",this,"onItemCardListPress");
	}

	function handleInput(details, pathToFocus)
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("InventoryMenu handleInput()");
		if (DEBUG_LEVEL > 1)
			_global.skse.Log("InventoryMenu handleInput() details = " + details.navEquivalent + ", object = " + details);
		if (_bFadedIn && !pathToFocus[0].handleInput(details, pathToFocus.slice(1))) {
			if (GlobalFunc.IsKeyPressed(details)) {
				if (details.navEquivalent == NavigationCode.TAB) {
					StartMenuFade();
					GameDelegate.call("CloseTweenMenu",[]);
				}
			}
		}
		return true;
	}

	function onExitMenuRectClick()
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("InventoryMenu onExitMenuRectClick()");
		StartMenuFade();
		GameDelegate.call("ShowTweenMenu",[]);
	}

	function StartMenuFade()
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("InventoryMenu StartMenuFade()");
		InventoryLists_mc.HideCategoriesList();
		ToggleMenuFade();
		SaveIndices();
		_bMenuClosing = true;
	}

	function onFadeCompletion()
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("InventoryMenu onFadeCompletion()");
		if (_bMenuClosing) {
			GameDelegate.call("CloseMenu",[]);
		}
	}

	function onShowItemsList(event)
	{
		super.onShowItemsList(event);
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("InventoryMenu onShowItemsList()");
		if (event.index != -1) {
			UpdateBottomBarButtons();
		}
	}

	function onItemHighlightChange(event)
	{
		super.onItemHighlightChange(event);
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("InventoryMenu onItemHighlightChange()");
		if (event.index != -1) {
			UpdateBottomBarButtons();
		}
	}

	function UpdateBottomBarButtons()
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("InventoryMenu UpdateBottomBarButtons()");
		BottomBar_mc.SetButtonArt(AltButtonArt,0);
		switch (ItemCard_mc.itemInfo.type) {
			case InventoryDefines.ICT_ARMOR :
					BottomBar_mc.SetButtonText("$Equip",0);
				break;

			case InventoryDefines.ICT_BOOK :
					BottomBar_mc.SetButtonText("$Read",0);
				break;

			case InventoryDefines.ICT_POTION :
					BottomBar_mc.SetButtonText("$Use",0);
				break;

			case InventoryDefines.ICT_FOOD :
			case InventoryDefines.ICT_INGREDIENT :
					BottomBar_mc.SetButtonText("$Eat",0);
				break;

			default :
					BottomBar_mc.SetButtonArt(EquipButtonArt,0);
					BottomBar_mc.SetButtonText("$Equip",0);
			}


		BottomBar_mc.SetButtonText("$Drop",1);
		if (InventoryLists_mc.ItemsList.selectedEntry.filterFlag & InventoryLists_mc.CategoriesList.entryList[0].flag != 0) {
			BottomBar_mc.SetButtonText("$Unfavorite",2);
		} else {
			BottomBar_mc.SetButtonText("$Favorite",2);
		}

		if (ItemCard_mc.itemInfo.charge != undefined && ItemCard_mc.itemInfo.charge < 100) {
			BottomBar_mc.SetButtonText("$Charge",3);
		} else {
			BottomBar_mc.SetButtonText("",3);
		}
	}

	function onHideItemsList(event)
	{
		super.onHideItemsList(event);
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("InventoryMenu onHideItemsList()");
		BottomBar_mc.UpdatePerItemInfo({type:InventoryDefines.ICT_NONE});
	}

	function onItemSelect(event)
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("InventoryMenu onItemSelect()");
		if (event.entry.enabled && event.keyboardOrMouse != 0) {
			GameDelegate.call("ItemSelect",[]);
		}
	}

	function AttemptEquip(a_slot, a_bCheckOverList)
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("InventoryMenu AttemptEquip()");
		var bCheckOverList = a_bCheckOverList != undefined ? a_bCheckOverList : (true);
		if (ShouldProcessItemsListInput(bCheckOverList) && ConfirmSelectedEntry()) {
			if (DEBUG_LEVEL > 1)
				_global.skse.Log("InventoryMenu AttemptEquip() ItemSelect");
			GameDelegate.call("ItemSelect",[a_slot]);
		}
	}

	function DropItem()
	{
                if (DEBUG_LEVEL > 0)
			_global.skse.Log("InventoryMenu DropItem()");
		if (ShouldProcessItemsListInput(false) && InventoryLists_mc.ItemsList.selectedEntry != undefined) {
			if (InventoryLists_mc.ItemsList.selectedEntry.count <= InventoryDefines.QUANTITY_MENU_COUNT_LIMIT) {
						onQuantityMenuSelect({amount:1});
			} else {
				ItemCard_mc.ShowQuantityMenu(InventoryLists_mc.ItemsList.selectedEntry.count);
			}
		}
	}

	function AttemptChargeItem() {
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("InventoryMenu AttemptChargeItem()");
		if (ShouldProcessItemsListInput(false) && ItemCard_mc.itemInfo.charge != undefined && ItemCard_mc.itemInfo.charge < 100) {
			if (DEBUG_LEVEL > 1)
				_global.skse.Log("InventoryMenu AttemtChargeItem() GameDelegate.call ShowSoulGemList");
			GameDelegate.call("ShowSoulGemList",[]);
		}
	}

	function onQuantityMenuSelect(event)
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("InventoryMenu onQuantityMenuSelect()");
		GameDelegate.call("ItemDrop",[event.amount]);
		
		// Bug Fix: ItemCard does not update when attempting to drop quest items through the quantity menu
		//			so let's request an update even though it may be redundant.
		GameDelegate.call("RequestItemCardInfo",[],this,"UpdateItemCardInfo");
	}

	function onMouseRotationFastClick(aiMouseButton)
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("InventoryMenu onMouseRotationFastClick()");
		GameDelegate.call("CheckForMouseEquip",[aiMouseButton],this,"AttemptEquip");
	}

	function onItemCardListPress(event)
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("InventoryMenu onItemCardListPress()");
		GameDelegate.call("ItemCardListCallback",[event.index]);
	}

	function onItemCardSubMenuAction(event)
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("InventoryMenu onItemCardSubMenuAction()");
		super.onItemCardSubMenuAction(event);
		GameDelegate.call("QuantitySliderOpen",[event.opening]);
		
		if (event.menu == "list") {
			if (event.opening == true) {
				PrevButtonArt = BottomBar_mc.GetButtonsArt();
				BottomBar_mc.SetButtonsText("$Select","$Cancel");
				BottomBar_mc.SetButtonsArt(ItemCardListButtonArt);
			} else {
				BottomBar_mc.SetButtonsArt(PrevButtonArt);
				PrevButtonArt = undefined;
				GameDelegate.call("RequestItemCardInfo",[],this,"UpdateItemCardInfo");
				UpdateBottomBarButtons();
			}
		}
	}

	function SetPlatform(a_platform, a_bPS3Switch)
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("InventoryMenu SetPlatform()");
		InventoryLists_mc.ZoomButtonHolderInstance.gotoAndStop(1);
		InventoryLists_mc.ZoomButtonHolderInstance.ZoomButton._visible = a_platform != 0;
		InventoryLists_mc.ZoomButtonHolderInstance.ZoomButton.SetPlatform(a_platform, a_bPS3Switch);
		super.SetPlatform(a_platform, a_bPS3Switch);
	}

	function ItemRotating()
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("InventoryMenu ItemRotating()");
		InventoryLists_mc.ZoomButtonHolderInstance.PlayForward(InventoryLists_mc.ZoomButtonHolderInstance._currentframe);
	}
}