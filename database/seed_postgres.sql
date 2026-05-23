-- ============================================================
-- DBMS 3 — PostgreSQL Audit Log Database
-- Database: ojt_auditdb
-- Run this AFTER creating the database:
--   CREATE DATABASE ojt_auditdb;
-- ============================================================

-- Drop table if exists for clean re-seeding
DROP TABLE IF EXISTS audit_logs;

-- Create the audit_logs table
CREATE TABLE audit_logs (
    log_id      SERIAL PRIMARY KEY,
    user_id     VARCHAR(20)   NOT NULL,
    username    VARCHAR(100)  NOT NULL,
    action      VARCHAR(30)   NOT NULL CHECK (action IN ('LOGIN', 'LOGOUT', 'REPORT_GENERATED')),
    details     VARCHAR(255),
    ip_address  VARCHAR(45),
    created_at  TIMESTAMP     DEFAULT NOW()
);

-- Create index on action for faster filtering
CREATE INDEX idx_audit_action ON audit_logs(action);
-- Create index on user_id for admin-specific queries
CREATE INDEX idx_audit_user ON audit_logs(user_id);
-- Create index on timestamp for chronological queries
CREATE INDEX idx_audit_time ON audit_logs(created_at DESC);

-- ============================================================
-- SEED DATA — 15 Sample Audit Log Entries
-- Uses realistic IDs from existing Derby + MySQL databases
-- ============================================================

INSERT INTO audit_logs (user_id, username, action, details, ip_address, created_at) VALUES
('ADM2026-0001', 'System Administrator', 'LOGIN', 'Admin logged in successfully', '127.0.0.1', '2026-05-01 08:15:22'),
('INT2020-10001', 'Backend Intern', 'LOGIN', 'Intern logged in successfully', '192.168.1.101', '2026-05-01 09:00:45'),
('ADM2026-0001', 'System Administrator', 'REPORT_GENERATED', 'Generated USERLIST report', '127.0.0.1', '2026-05-01 10:30:00'),
('INT2020-10001', 'Backend Intern', 'LOGOUT', 'User session ended', '192.168.1.101', '2026-05-01 17:05:12'),
('ADM2026-0001', 'System Administrator', 'REPORT_GENERATED', 'Generated OJTLOGS report (2026-05-01 to 2026-05-05)', '127.0.0.1', '2026-05-02 14:22:33'),
('INT2020-10002', 'UI/UX Intern', 'LOGIN', 'Intern logged in successfully', '192.168.1.102', '2026-05-03 08:45:10'),
('ADM2026-0001', 'System Administrator', 'LOGOUT', 'Admin session ended', '127.0.0.1', '2026-05-03 18:00:00'),
('INT2024-50001', 'Backend Intern Sr', 'LOGIN', 'Intern logged in successfully', '192.168.1.110', '2026-05-04 07:55:30'),
('INT2024-50001', 'Backend Intern Sr', 'LOGOUT', 'User session ended', '192.168.1.110', '2026-05-04 16:30:45'),
('ADM2026-0001', 'System Administrator', 'LOGIN', 'Admin logged in successfully', '127.0.0.1', '2026-05-05 08:00:00'),
('ADM2026-0001', 'System Administrator', 'REPORT_GENERATED', 'Generated ADMINRECORD report', '127.0.0.1', '2026-05-05 11:15:20'),
('INT2026-70001', 'New Backend Intern', 'LOGIN', 'Intern logged in successfully', '192.168.1.120', '2026-05-06 09:10:00'),
('ADM2026-0001', 'System Administrator', 'REPORT_GENERATED', 'Generated AUDITLOG report', '127.0.0.1', '2026-05-07 15:45:00'),
('INT2026-70001', 'New Backend Intern', 'LOGOUT', 'User session ended', '192.168.1.120', '2026-05-07 17:30:00'),
('ADM2026-0001', 'System Administrator', 'LOGOUT', 'Admin session ended', '127.0.0.1', '2026-05-07 18:00:00');
