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
  `SUBMISSION_ID` varchar(30) NOT NULL,
  `USER_ID` varchar(20) NOT NULL,
  `DATE_SUBMITTED` date NOT NULL,
  `DESCRIPTION` text,
  `LEARNING_REFLECTION` text DEFAULT NULL,
  `SUPPORTING_FILE` varchar(255) DEFAULT NULL,
  `ORIGINAL_FILE_NAME` varchar(255) DEFAULT NULL,
  `STATUS` varchar(20) DEFAULT 'Pending',
  PRIMARY KEY (`SUBMISSION_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `activity_submissions`
--

LOCK TABLES `activity_submissions` WRITE;
/*!40000 ALTER TABLE `activity_submissions` DISABLE KEYS */;
INSERT INTO `activity_submissions` VALUES ('20260501-BE-0001','INT2020-10001','2026-05-01','Completed documentation for Backend API','I learned how backend APIs process requests and return data.','doc_001.pdf','api_docs.pdf','Approved'),('20260502-UIUX-0002','INT2020-10002','2026-05-02','Designed High-Fidelity Prototypes for Login','I learned UI/UX best practices and how to design premium dark interfaces.','design_v1.png','login_wireframe.png','Pending'),('20260503-QA-0003','INT2020-10004','2026-05-03','Executed 15 test cases for the Dashboard','I learned about boundary testing and QA reporting.','qa_report.xlsx','test_results.xlsx','Rejected'),('20260504-FE-0004','INT2020-10005','2026-05-04','Implemented responsive Navbar using CSS Grid','I learned CSS layout techniques and standard grid systems.','nav_fix.zip','frontend_update.zip','Pending'),('20260505-BE-0005','INT2024-50001','2026-05-05','Optimized database queries for Intern list','I learned how to run index scans to speed up queries.','sql_opt.txt','query_fixes.txt','Approved'),('20260506-DA-0006','INT2024-50003','2026-05-06','Setup ETL pipeline for Office 1 data','I learned how data pipelines transform legacy formats.','etl_script.py','main.py','Pending'),('20260506-QA-0007','INT2024-50004','2026-05-06','Bug report: fixed 3 critical UI glitches','I learned how to debug layout rendering issues on older systems.','bug_fix.txt','patch_notes.txt','Pending'),('20260507-BE-0009','INT2025-60001','2026-05-07','API Integration with 3rd party auth','I learned standard OAuth2 handshake protocols.','auth_logic.java','AuthHandler.java','Pending'),('20260507-FE-0008','INT2024-50005','2026-05-07','Refactored JavaScript for search filtering','I learned JavaScript performance optimization for filtering lists.','search.js','app.js','Pending'),('20260508-DA-0011','INT2025-60003','2026-05-08','Statistical analysis for User Growth','I learned regression modeling and data visualization.','stats.xlsx','growth_report.xlsx','Approved'),('20260508-QA-0012','INT2025-60004','2026-05-08','Drafted test scripts for Login module','I learned how to write comprehensive test scripts.','test_scripts.zip','scripts.zip','Pending'),('20260508-UIUX-0010','INT2025-60002','2026-05-08','Color palette and typography audit','I learned how typography choices influence user visual comfort.','brand_audit.pdf','style_guide.pdf','Pending'),('20260509-BE-0013','INT2026-70001','2026-05-09','Configured Apache Derby schema for OJT','I learned schema constraints in localized embedded databases.','db_schema.sql','schema.sql','Pending'),('20260509-UIUX-0014','INT2026-70002','2026-05-09','Wireframed mobile view for Intern logs','I learned responsive wireframing for portrait layouts.','mobile_wf.pdf','mobile_wireframe.pdf','Pending'),('20260510-BE-0018','INT2026-70006','2026-05-10','Integrated iText for PDF generation','I learned programmatic page flow and layout handling in iText.','itext_impl.java','ReportGenerator.java','Pending'),('20260510-DA-0015','INT2026-70003','2026-05-10','Data Migration script from CSV to SQL','I learned schema parsing and data cleaning practices.','migrate.py','migration_v2.py','Rejected'),('20260510-DA-0019','INT2026-70008','2026-05-10','SQL Indexing for faster search queries','I learned indexing columns for search optimization.','indexes.sql','optimization.sql','Approved'),('20260510-FE-0017','INT2026-70005','2026-05-10','Styled error pages (404, 500)','I learned error status codes and customized messaging page design.','errors.css','error_styles.css','Pending'),('20260510-FE-0021','INT2026-70010','2026-05-10','Updated Bootstrap 5 components','I learned container classes and utility systems in Bootstrap 5.','bs5_update.html','index_new.html','Pending'),('20260510-QA-0016','INT2026-70004','2026-05-10','End-to-end testing of Logout functionality','I learned session clearing processes and cookies removal flow.','e2e_report.pdf','logout_test.pdf','Approved'),('20260510-QA-0020','INT2026-70009','2026-05-10','Regression testing for Security Filter','I learned how security filters scan requests for CSRF and XSS.','sec_test.docx','security_audit.docx','Pending');
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
  `INTERN_ID` varchar(20) NOT NULL,
  `LOG_DATE` date NOT NULL,
  `TIME_IN` time DEFAULT NULL,
  `TIME_OUT` time DEFAULT NULL,
  `RENDERED_HOURS` decimal(5,2) DEFAULT NULL,
  `COMPLETED_HOURS` decimal(5,2) DEFAULT NULL,
  PRIMARY KEY (`LOG_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
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

-- Dump completed on 2026-05-17 23:39:11
