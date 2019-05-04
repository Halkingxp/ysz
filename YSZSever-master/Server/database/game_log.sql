/*
Navicat MySQL Data Transfer

Source Server         : 127.0.0.1-本地(localhost)
Source Server Version : 50717
Source Host           : localhost:3306
Source Database       : game_log

Target Server Type    : MYSQL
Target Server Version : 50717
File Encoding         : 65001

Date: 2017-09-22 09:56:31
*/

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for `log_email`
-- ----------------------------
DROP TABLE IF EXISTS `log_email`;
CREATE TABLE `log_email` (
  `log_ID` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '序号',
  `log_SenderID` int(11) unsigned DEFAULT '0' COMMENT '发送者帐号ID',
  `log_ReceiveID` int(11) unsigned DEFAULT '0' COMMENT '接收者帐号ID',
  `log_Gold` bigint(19) unsigned DEFAULT '0' COMMENT '附件金币总数',
  `log_Cost` bigint(19) unsigned DEFAULT '0' COMMENT '附件金币抽成',
  `log_Time` datetime DEFAULT '0000-00-00 00:00:00' COMMENT '日志时间',
  PRIMARY KEY (`log_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Records of log_email
-- ----------------------------

-- ----------------------------
-- Table structure for `log_gold`
-- ----------------------------
DROP TABLE IF EXISTS `log_gold`;
CREATE TABLE `log_gold` (
  `log_ID` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '序号',
  `log_AccountID` int(11) unsigned DEFAULT '0' COMMENT '玩家AccountID',
  `log_ChangeValue` bigint(19) DEFAULT '0' COMMENT '改变值',
  `log_Value` bigint(19) unsigned DEFAULT '0' COMMENT '改变后剩余值',
  `log_Operate` int(11) unsigned DEFAULT '0' COMMENT '改变原因',
  `log_Time` datetime DEFAULT '2016-01-01 23:59:59' COMMENT '改变时间',
  `log_RoomID` int(11) unsigned DEFAULT '0' COMMENT '房间ID',
  PRIMARY KEY (`log_ID`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Records of log_gold
-- ----------------------------
INSERT INTO `log_gold` VALUES ('9', '1000001', '10000000', '10000000', '1', '2017-09-21 19:01:39', '0');

-- ----------------------------
-- Table structure for `log_login`
-- ----------------------------
DROP TABLE IF EXISTS `log_login`;
CREATE TABLE `log_login` (
  `log_ID` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '序号',
  `log_AccountID` int(11) unsigned DEFAULT '0' COMMENT '玩家AccountID',
  `log_LoginTime` datetime DEFAULT '2016-01-01 23:59:59' COMMENT '登录时间',
  `log_LogoutTime` datetime DEFAULT NULL COMMENT '玩家离线时间',
  PRIMARY KEY (`log_ID`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=COMPACT;

-- ----------------------------
-- Records of log_login
-- ----------------------------
INSERT INTO `log_login` VALUES ('3', '1000001', '2017-09-21 17:09:46', null);
INSERT INTO `log_login` VALUES ('4', '1000001', '2017-09-21 17:41:08', '2017-09-21 17:41:32');
INSERT INTO `log_login` VALUES ('5', '1000001', '2017-09-21 17:41:33', '2017-09-21 17:41:33');
INSERT INTO `log_login` VALUES ('6', '1000001', '2017-09-21 17:42:11', '2017-09-21 17:42:24');
INSERT INTO `log_login` VALUES ('7', '1000001', '2017-09-21 17:46:43', '2017-09-21 17:46:52');
INSERT INTO `log_login` VALUES ('8', '1000001', '2017-09-21 18:53:35', '2017-09-21 18:54:08');
INSERT INTO `log_login` VALUES ('9', '1000001', '2017-09-21 18:56:28', '2017-09-21 18:56:36');
INSERT INTO `log_login` VALUES ('10', '1000001', '2017-09-21 18:57:27', '2017-09-21 19:02:17');

-- ----------------------------
-- Table structure for `log_money_daily`
-- ----------------------------
DROP TABLE IF EXISTS `log_money_daily`;
CREATE TABLE `log_money_daily` (
  `log_ID` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '序号',
  `log_MoneyName` varchar(32) DEFAULT NULL,
  `log_Money` bigint(19) unsigned DEFAULT NULL,
  `log_Time` datetime DEFAULT NULL,
  PRIMARY KEY (`log_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Records of log_money_daily
-- ----------------------------

-- ----------------------------
-- Table structure for `log_online`
-- ----------------------------
DROP TABLE IF EXISTS `log_online`;
CREATE TABLE `log_online` (
  `log_ID` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '序号',
  `log_MaxOnline` int(11) unsigned DEFAULT '0' COMMENT '最高在线人数',
  `log_Online` int(11) unsigned DEFAULT '0' COMMENT '在线人数',
  `log_NewCount` int(11) DEFAULT '0' COMMENT '新增人数',
  `log_ProfitGold` int(11) DEFAULT '0' COMMENT '收益率',
  `log_Time` datetime DEFAULT '2017-01-01 23:59:59' COMMENT '日志时间',
  PRIMARY KEY (`log_ID`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Records of log_online
-- ----------------------------
INSERT INTO `log_online` VALUES ('3', '1', '0', '0', '0', '2017-09-21 19:12:40');

-- ----------------------------
-- Table structure for `log_rmb`
-- ----------------------------
DROP TABLE IF EXISTS `log_rmb`;
CREATE TABLE `log_rmb` (
  `log_ID` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '序号',
  `log_AccountID` int(11) unsigned DEFAULT '0' COMMENT '玩家AccountID',
  `log_ChangeValue` bigint(19) DEFAULT '0' COMMENT '改变值',
  `log_Value` bigint(19) unsigned DEFAULT '0' COMMENT '改变后剩余值',
  `log_Operate` int(11) unsigned DEFAULT '0' COMMENT '改变原因',
  `log_Time` datetime DEFAULT '2016-01-01 23:59:59' COMMENT '改变时间',
  `log_RoomID` int(11) unsigned DEFAULT '0' COMMENT '房间ID',
  PRIMARY KEY (`log_ID`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Records of log_rmb
-- ----------------------------

-- ----------------------------
-- Table structure for `log_roomcard`
-- ----------------------------
DROP TABLE IF EXISTS `log_roomcard`;
CREATE TABLE `log_roomcard` (
  `log_ID` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '序号',
  `log_AccountID` int(11) unsigned DEFAULT '0' COMMENT '玩家AccountID',
  `log_ChangeValue` int(11) DEFAULT '0' COMMENT '改变值',
  `log_Value` int(11) unsigned DEFAULT '0' COMMENT '改变后剩余值',
  `log_Operate` int(11) unsigned DEFAULT '0' COMMENT '改变原因',
  `log_Time` datetime DEFAULT '2016-01-01 23:59:59' COMMENT '改变时间',
  `log_RoomID` int(11) unsigned DEFAULT '0' COMMENT '房间ID',
  PRIMARY KEY (`log_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Records of log_roomcard
-- ----------------------------

-- ----------------------------
-- Table structure for `log_room_daily`
-- ----------------------------
DROP TABLE IF EXISTS `log_room_daily`;
CREATE TABLE `log_room_daily` (
  `log_ID` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '序号',
  `log_RoomID` int(11) unsigned DEFAULT '0' COMMENT '房间ID',
  `log_Board` int(11) unsigned DEFAULT '0' COMMENT '牌局总次数',
  `log_LongWin` int(11) unsigned DEFAULT '0' COMMENT '龙赢次数',
  `log_HuWin` int(11) unsigned DEFAULT '0' COMMENT '虎赢次数',
  `log_He` int(11) unsigned DEFAULT '0' COMMENT '和局次数',
  `log_LongJinHua` int(11) unsigned DEFAULT '0' COMMENT '龙金花次数',
  `log_Baozi` int(11) unsigned DEFAULT '0' COMMENT '龙虎豹子次数',
  `log_HuJinHua` int(11) unsigned DEFAULT '0' COMMENT '虎金花次数',
  `log_YaLong` bigint(19) unsigned DEFAULT '0' COMMENT '龙押注总金额',
  `log_YaHu` bigint(19) unsigned DEFAULT '0' COMMENT '虎押注总金额',
  `log_YaLongJinHua` bigint(19) unsigned DEFAULT '0' COMMENT '龙金花押注总金额',
  `log_YaBaozi` bigint(19) unsigned DEFAULT '0' COMMENT '龙虎豹子押注总金额',
  `log_YaHuJinHua` bigint(19) unsigned DEFAULT '0' COMMENT '虎金花押注总金额',
  `log_SystemBanker` int(11) unsigned DEFAULT '0' COMMENT '系统当庄局数',
  `log_SystemProfitGold` bigint(19) DEFAULT '0' COMMENT '系统当庄累积输赢金币数',
  `log_SystemCommission` bigint(19) unsigned DEFAULT '0' COMMENT '系统抽水总金额',
  `log_PlayerBanker` int(11) unsigned DEFAULT '0' COMMENT '玩家当庄局数',
  `log_PlayerProfitGold` bigint(19) DEFAULT '0' COMMENT '玩家当庄累积输赢金币数',
  `log_PlayerCommission` bigint(19) unsigned DEFAULT '0' COMMENT '玩家庄家抽水总金额',
  `log_Time` datetime DEFAULT '0000-00-00 00:00:00' COMMENT '日志时间',
  PRIMARY KEY (`log_ID`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Records of log_room_daily
-- ----------------------------

-- ----------------------------
-- Table structure for `log_settlement`
-- ----------------------------
DROP TABLE IF EXISTS `log_settlement`;
CREATE TABLE `log_settlement` (
  `log_ID` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '序号',
  `log_AccountID` int(11) unsigned DEFAULT '0' COMMENT '角色帐号ID',
  `log_RoomID` int(11) unsigned DEFAULT '0' COMMENT '房间ID',
  `log_Banker` tinyint(1) unsigned DEFAULT '0' COMMENT '是否是庄家(1:庄家, 0玩家)',
  `log_YaLong` int(11) unsigned DEFAULT '0' COMMENT '龙押注金额',
  `log_YaHu` int(11) unsigned DEFAULT '0' COMMENT '虎押注金额',
  `log_YaLongJinHua` int(11) unsigned DEFAULT '0' COMMENT '龙金花押注金额',
  `log_YaBaozi` int(11) unsigned DEFAULT '0' COMMENT '龙虎豹子押注金额',
  `log_YaHuJinHua` int(11) unsigned DEFAULT '0' COMMENT '虎金花押注金额',
  `log_Result` varchar(20) DEFAULT '' COMMENT '牌局结果',
  `log_LongType` varchar(20) DEFAULT '' COMMENT '龙牌型',
  `log_HuType` varchar(20) DEFAULT '' COMMENT '虎牌型',
  `log_ChangeGold` int(11) DEFAULT '0' COMMENT '本局输赢金币数',
  `log_Time` datetime DEFAULT '0000-00-00 00:00:00' COMMENT '日志时间',
  PRIMARY KEY (`log_ID`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Records of log_settlement
-- ----------------------------

-- ----------------------------
-- Table structure for `log_vip`
-- ----------------------------
DROP TABLE IF EXISTS `log_vip`;
CREATE TABLE `log_vip` (
  `log_ID` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '序号',
  `log_Vip0` int(11) unsigned DEFAULT '0' COMMENT 'VIP0人数',
  `log_Vip1` int(11) unsigned DEFAULT '0' COMMENT 'VIP1人数',
  `log_Vip2` int(11) unsigned DEFAULT '0' COMMENT 'VIP2人数',
  `log_Vip3` int(11) unsigned DEFAULT '0' COMMENT 'VIP3人数',
  `log_Vip4` int(11) unsigned DEFAULT '0' COMMENT 'VIP4人数',
  `log_Vip5` int(11) unsigned DEFAULT '0' COMMENT 'VIP5人数',
  `log_Vip6` int(11) unsigned DEFAULT '0' COMMENT 'VIP6人数',
  `log_Vip7` int(11) unsigned DEFAULT '0' COMMENT 'VIP7人数',
  `log_Vip8` int(11) unsigned DEFAULT '0' COMMENT 'VIP8人数',
  `log_Vip9` int(11) unsigned DEFAULT '0' COMMENT 'VIP9人数',
  `log_Time` datetime DEFAULT '0000-00-00 00:00:00' COMMENT '日志时间',
  PRIMARY KEY (`log_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------
-- Records of log_vip
-- ----------------------------
