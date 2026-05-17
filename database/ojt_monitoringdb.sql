-- MySQL dump 10.13  Distrib 8.0.46, for Win64 (x86_64)
--
-- Host: localhost    Database: ojt_monitoringdb
-- ------------------------------------------------------
-- Server version	8.0.46

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `activity_submissions`
--

DROP TABLE IF EXISTS `activity_submissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `activity_submissions` (
  `SUBMISSION_ID` int NOT NULL AUTO_INCREMENT,
  `USER_ID` int NOT NULL,
  `DATE_SUBMITTED` date NOT NULL,
  `DESCRIPTION` text,
  `SUPPORTING_FILE` varchar(255) DEFAULT NULL,
  `ORIGINAL_FILE_NAME` varchar(255) DEFAULT NULL,
  `STATUS` varchar(20) DEFAULT 'Pending',
  PRIMARY KEY (`SUBMISSION_ID`)
) ENGINE=InnoDB AUTO_INCREMENT=26 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `activity_submissions`
--

LOCK TABLES `activity_submissions` WRITE;
/*!40000 ALTER TABLE `activity_submissions` DISABLE KEYS */;
INSERT INTO `activity_submissions` VALUES (1,1,'2026-05-01','Completed documentation for Backend API','doc_001.pdf','api_docs.pdf','Approved'),(2,2,'2026-05-02','Designed High-Fidelity Prototypes for Login','design_v1.png','login_wireframe.png','Pending'),(3,3,'2026-05-02','Cleaned dataset for quarterly reports','data_clean.csv','intern_data.csv','Pending'),(4,4,'2026-05-03','Executed 15 test cases for the Dashboard','qa_report.xlsx','test_results.xlsx','Rejected'),(5,5,'2026-05-04','Implemented responsive Navbar using CSS Grid','nav_fix.zip','frontend_update.zip','Pending'),(6,6,'2026-05-05','Optimized database queries for Intern list','sql_opt.txt','query_fixes.txt','Approved'),(7,7,'2026-05-05','User research survey results analysis','survey.pdf','ux_research.pdf','Pending'),(8,8,'2026-05-06','Setup ETL pipeline for Office 1 data','etl_script.py','main.py','Pending'),(9,9,'2026-05-06','Bug report: fixed 3 critical UI glitches','bug_fix.txt','patch_notes.txt','Pending'),(10,10,'2026-05-07','Refactored JavaScript for search filtering','search.js','app.js','Pending'),(11,11,'2026-05-07','API Integration with 3rd party auth','auth_logic.java','AuthHandler.java','Pending'),(12,12,'2026-05-08','Color palette and typography audit','brand_audit.pdf','style_guide.pdf','Pending'),(13,13,'2026-05-08','Statistical analysis for User Growth','stats.xlsx','growth_report.xlsx','Approved'),(14,14,'2026-05-08','Drafted test scripts for Login module','test_scripts.zip','scripts.zip','Pending'),(15,15,'2026-05-09','Fixed CSS alignment in Admin Panel','admin_ui.css','style.css','Approved'),(16,16,'2026-05-09','Configured Apache Derby schema for OJT','db_schema.sql','schema.sql','Pending'),(17,17,'2026-05-09','Wireframed mobile view for Intern logs','mobile_wf.pdf','mobile_wireframe.pdf','Pending'),(18,18,'2026-05-10','Data Migration script from CSV to SQL','migrate.py','migration_v2.py','Rejected'),(19,19,'2026-05-10','End-to-end testing of Logout functionality','e2e_report.pdf','logout_test.pdf','Approved'),(20,20,'2026-05-10','Styled error pages (404, 500)','errors.css','error_styles.css','Pending'),(21,21,'2026-05-10','Integrated iText for PDF generation','itext_impl.java','ReportGenerator.java','Pending'),(22,22,'2026-05-10','Interactive Prototype for Landing Page','proto.figma','landing_proto.figma','Pending'),(23,23,'2026-05-10','SQL Indexing for faster search queries','indexes.sql','optimization.sql','Approved'),(24,24,'2026-05-10','Regression testing for Security Filter','sec_test.docx','security_audit.docx','Pending'),(25,25,'2026-05-10','Updated Bootstrap 5 components','bs5_update.html','index_new.html','Pending');
/*!40000 ALTER TABLE `activity_submissions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `internship_logs`
--

DROP TABLE IF EXISTS `internship_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `internship_logs` (
  `LOG_ID` int NOT NULL AUTO_INCREMENT,
  `INTERN_ID` int NOT NULL,
  `LOG_DATE` date NOT NULL,
  `TIME_IN` time DEFAULT NULL,
  `TIME_OUT` time DEFAULT NULL,
  `RENDERED_HOURS` decimal(5,2) DEFAULT NULL,
  `COMPLETED_HOURS` decimal(5,2) DEFAULT NULL,
  PRIMARY KEY (`LOG_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `internship_logs`
--

LOCK TABLES `internship_logs` WRITE;
/*!40000 ALTER TABLE `internship_logs` DISABLE KEYS */;
/*!40000 ALTER TABLE `internship_logs` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-05-17 15:05:55
