/*
Navicat MySQL Data Transfer

Source Server         : 127.0.0.1-本地(localhost)
Source Server Version : 50717
Source Host           : localhost:3306
Source Database       : game_inst

Target Server Type    : MYSQL
Target Server Version : 50717
File Encoding         : 65001

Date: 2017-09-22 09:56:20
*/

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for `gd_account`
-- ----------------------------
DROP TABLE IF EXISTS `gd_account`;
CREATE TABLE `gd_account` (
  `gd_Account` varchar(128) NOT NULL DEFAULT '' COMMENT '账号ID',
  `gd_BindAccount` varchar(128) NOT NULL,
  `gd_AccountID` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '帐号ID',
  `gd_Name` varchar(21) NOT NULL COMMENT '名字',
  `gd_HeadID` tinyint(2) NOT NULL DEFAULT '0' COMMENT '头像ID',
  `gd_RMB` bigint(19) unsigned NOT NULL DEFAULT '0' COMMENT '钻石',
  `gd_Gold` bigint(19) unsigned NOT NULL DEFAULT '0' COMMENT '金币',
  `gd_RoomCard` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '房卡',
  `gd_Charge` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '累积充值RMB',
  `gd_VIPLv` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT 'VIP等级',
  `gd_Free` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '已免费次数',
  `gd_FreeGold` bigint(19) unsigned NOT NULL DEFAULT '0' COMMENT '免费试玩金币',
  `gd_ActiveTime` datetime NOT NULL DEFAULT '2015-11-01 23:59:59' COMMENT '激活帐号时刻',
  `gd_ActiveIP` varchar(20) NOT NULL DEFAULT '0.0.0.0' COMMENT '激活帐号IP',
  `gd_PlatformID` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '平台ID',
  `gd_ChannelID` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '渠道ID',
  `gd_YesterdayGold` bigint(19) unsigned NOT NULL DEFAULT '0' COMMENT '玩家前一天的金币数',
  `gd_DaliyFreeEmailNum` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '玩家每日已用免费邮件发送次数',
  `gd_FrozenTime` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '冻结限制到期时间',
  PRIMARY KEY (`gd_Account`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Records of gd_account
-- ----------------------------
INSERT INTO `gd_account` VALUES ('9768cf79b8a3f49c96e6cc1508f6aa57af4877ee', '', '1000001', '赌圣101126', '10', '0', '10000000', '0', '0', '0', '2', '0', '2017-09-21 17:09:46', '192.168.2.48', '1', '1', '0', '0', '0');

-- ----------------------------
-- Table structure for `gd_account2`
-- ----------------------------
DROP TABLE IF EXISTS `gd_account2`;
CREATE TABLE `gd_account2` (
  `gd_AccountID` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '游戏帐号ID',
  `gd_Salesman` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '推广员身份, 0普通, 1申请中, 2推广员',
  `gd_SendEmail` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '是否发送邀请邮件(1发送)',
  `gd_TotalBetting` bigint(19) unsigned NOT NULL DEFAULT '0' COMMENT '累积下注金额',
  `gd_TotalRebate` bigint(19) unsigned NOT NULL DEFAULT '0' COMMENT '今日累积返利下注金币',
  `gd_BindCode` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '绑定邀请码',
  `gd_OneNumber` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '一级下线人数',
  `gd_OneBetting` bigint(19) unsigned NOT NULL DEFAULT '0' COMMENT '一级下线返利的下注金额',
  `gd_TwoNumber` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '二级下线人数',
  `gd_TwoBetting` bigint(19) unsigned NOT NULL DEFAULT '0' COMMENT '二级下线返利的下注金额',
  `gd_GiveGold` bigint(19) unsigned NOT NULL DEFAULT '0' COMMENT '已发放返利金币数',
  `gd_ChangeName` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '改名次数',
  `gd_Win` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '胜次数',
  `gd_Lose` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '输次数',
  `gd_He` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '和次数',
  `gd_SaleAccount` varchar(10) NOT NULL DEFAULT '' COMMENT '推广员帐号',
  `gd_TotalDealer` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '所属总代理帐号ID',
  `gd_Downline` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '所属总代理的第几层下线',
  `gd_TDNumber` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '总代理的总下线人数',
  `gd_TDBetting` bigint(19) unsigned NOT NULL DEFAULT '0' COMMENT '总代理返利的总下注金币',
  `gd_SalesTime` varchar(20) DEFAULT '' COMMENT '成为推广员时间',
  `gd_EmailSendGold` bigint(19) unsigned NOT NULL DEFAULT '0' COMMENT '邮件发送总累积',
  `gd_EmailRecvGold` bigint(19) unsigned NOT NULL DEFAULT '0' COMMENT '邮件接收总累积',
  `gd_WeiXinCharge` bigint(19) unsigned NOT NULL DEFAULT '0' COMMENT '微信充值总累积',
  `gd_AlipayCharge` bigint(19) unsigned NOT NULL DEFAULT '0' COMMENT '支付宝充值总累积',
  `gd_OtherCharge` bigint(19) unsigned NOT NULL DEFAULT '0' COMMENT '其他充值总额',
  PRIMARY KEY (`gd_AccountID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Records of gd_account2
-- ----------------------------
INSERT INTO `gd_account2` VALUES ('1000001', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '', '0', '0', '0', '0', '', '0', '0', '0', '0', '0');

-- ----------------------------
-- Table structure for `gd_email`
-- ----------------------------
DROP TABLE IF EXISTS `gd_email`;
CREATE TABLE `gd_email` (
  `gd_AccountID` int(11) unsigned NOT NULL DEFAULT '0' COMMENT 'HeroID, 特例ID1:全服邮件',
  `gd_Email` text NOT NULL COMMENT '邮件序列化',
  PRIMARY KEY (`gd_AccountID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Records of gd_email
-- ----------------------------

-- ----------------------------
-- Table structure for `gd_game`
-- ----------------------------
DROP TABLE IF EXISTS `gd_game`;
CREATE TABLE `gd_game` (
  `gd_ID` int(11) unsigned NOT NULL DEFAULT '1' COMMENT '序号',
  `gd_ProfitGold` bigint(19) NOT NULL DEFAULT '0' COMMENT '游戏全局收益金币(可为负数)',
  `gd_DailyRebate` text COMMENT '每日返利表',
  PRIMARY KEY (`gd_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Records of gd_game
-- ----------------------------
INSERT INTO `gd_game` VALUES ('1', '0', 'do local ret = {} return ret end');

-- ----------------------------
-- Table structure for `gd_payorder`
-- ----------------------------
DROP TABLE IF EXISTS `gd_payorder`;
CREATE TABLE `gd_payorder` (
  `gd_Order` varchar(128) CHARACTER SET utf8 NOT NULL DEFAULT '' COMMENT '订单ID',
  `gd_AccountID` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '帐号ID',
  `gd_CommodityID` tinyint(2) unsigned NOT NULL DEFAULT '0' COMMENT '商品ID',
  `gd_Amount` int(11) NOT NULL DEFAULT '0' COMMENT '支付金额',
  `gd_PayTime` datetime NOT NULL COMMENT '支付时间',
  `gd_PayCannel` tinyint(2) unsigned NOT NULL DEFAULT '0' COMMENT '支付渠道(152微信, 153支付宝, 154盛付通)',
  `gd_PayIP` varchar(20) NOT NULL DEFAULT '0' COMMENT '支付时的IP',
  PRIMARY KEY (`gd_Order`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Records of gd_payorder
-- ----------------------------

-- ----------------------------
-- Table structure for `hd_account`
-- ----------------------------
DROP TABLE IF EXISTS `hd_account`;
CREATE TABLE `hd_account` (
  `gd_Account` varchar(128) NOT NULL DEFAULT '' COMMENT '帐号',
  `gd_Password` varchar(64) NOT NULL DEFAULT '' COMMENT '绑定帐号',
  `gd_ServerID` smallint(2) unsigned NOT NULL DEFAULT '4' COMMENT '所属服务器ID',
  PRIMARY KEY (`gd_Account`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Records of hd_account
-- ----------------------------
INSERT INTO `hd_account` VALUES ('9768cf79b8a3f49c96e6cc1508f6aa57af4877ee', '', '10');
