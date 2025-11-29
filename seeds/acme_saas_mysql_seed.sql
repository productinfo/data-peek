-- ============================================================================
-- ACME SaaS - Sample Database for data-peek (MySQL Version)
-- ============================================================================
-- A fictional SaaS platform database with realistic structure and data.
-- Perfect for testing, demos, and screenshots.
-- ============================================================================

-- Use the database
-- CREATE DATABASE IF NOT EXISTS playground;
-- USE playground;

-- ============================================================================
-- TABLES
-- ============================================================================

-- Users
CREATE TABLE users (
    id CHAR(36) PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    avatar_url VARCHAR(512),
    email_verified_at DATETIME,
    last_login_at DATETIME,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_users_email (email),
    INDEX idx_users_created_at (created_at)
);

-- Organizations
CREATE TABLE organizations (
    id CHAR(36) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) NOT NULL UNIQUE,
    plan ENUM('free', 'starter', 'pro', 'enterprise') NOT NULL DEFAULT 'free',
    logo_url VARCHAR(512),
    website VARCHAR(255),
    billing_email VARCHAR(255),
    metadata JSON,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_organizations_slug (slug),
    INDEX idx_organizations_plan (plan)
);

-- Memberships (users <-> organizations)
CREATE TABLE memberships (
    id CHAR(36) PRIMARY KEY,
    user_id CHAR(36) NOT NULL,
    organization_id CHAR(36) NOT NULL,
    role ENUM('owner', 'admin', 'member', 'viewer') NOT NULL DEFAULT 'member',
    invited_by CHAR(36),
    joined_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE KEY unique_user_org (user_id, organization_id),
    INDEX idx_memberships_user_id (user_id),
    INDEX idx_memberships_organization_id (organization_id),
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    FOREIGN KEY (invited_by) REFERENCES users(id) ON DELETE SET NULL
);

-- Projects
CREATE TABLE projects (
    id CHAR(36) PRIMARY KEY,
    organization_id CHAR(36) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    status ENUM('active', 'paused', 'archived', 'deleted') NOT NULL DEFAULT 'active',
    settings JSON,
    created_by CHAR(36),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_projects_organization_id (organization_id),
    INDEX idx_projects_status (status),
    
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
);

-- API Keys
CREATE TABLE api_keys (
    id CHAR(36) PRIMARY KEY,
    organization_id CHAR(36) NOT NULL,
    name VARCHAR(100) NOT NULL,
    key_prefix VARCHAR(12) NOT NULL,
    key_hash VARCHAR(255) NOT NULL,
    scopes JSON,
    last_used_at DATETIME,
    expires_at DATETIME,
    created_by CHAR(36),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    revoked_at DATETIME,
    
    INDEX idx_api_keys_organization_id (organization_id),
    INDEX idx_api_keys_key_prefix (key_prefix),
    
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
);

-- Subscriptions
CREATE TABLE subscriptions (
    id CHAR(36) PRIMARY KEY,
    organization_id CHAR(36) NOT NULL,
    plan ENUM('free', 'starter', 'pro', 'enterprise') NOT NULL,
    status ENUM('active', 'past_due', 'canceled', 'trialing') NOT NULL DEFAULT 'active',
    stripe_subscription_id VARCHAR(100),
    stripe_customer_id VARCHAR(100),
    current_period_start DATETIME NOT NULL,
    current_period_end DATETIME NOT NULL,
    cancel_at DATETIME,
    canceled_at DATETIME,
    trial_end DATETIME,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_subscriptions_organization_id (organization_id),
    INDEX idx_subscriptions_status (status),
    
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE
);

-- Invoices
CREATE TABLE invoices (
    id CHAR(36) PRIMARY KEY,
    organization_id CHAR(36) NOT NULL,
    subscription_id CHAR(36),
    stripe_invoice_id VARCHAR(100),
    amount_cents INT NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    status ENUM('draft', 'pending', 'paid', 'failed', 'refunded') NOT NULL DEFAULT 'pending',
    description VARCHAR(500),
    invoice_url VARCHAR(512),
    pdf_url VARCHAR(512),
    due_date DATETIME,
    paid_at DATETIME,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_invoices_organization_id (organization_id),
    INDEX idx_invoices_status (status),
    INDEX idx_invoices_created_at (created_at),
    
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    FOREIGN KEY (subscription_id) REFERENCES subscriptions(id) ON DELETE SET NULL
);

-- Events (audit log / activity feed)
CREATE TABLE events (
    id CHAR(36) PRIMARY KEY,
    organization_id CHAR(36),
    user_id CHAR(36),
    type ENUM('user.created', 'user.updated', 'org.created', 'project.created', 'subscription.started', 'subscription.canceled', 'invoice.paid', 'api_key.created') NOT NULL,
    resource_type VARCHAR(50),
    resource_id CHAR(36),
    payload JSON,
    ip_address VARCHAR(45),
    user_agent VARCHAR(500),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_events_organization_id (organization_id),
    INDEX idx_events_user_id (user_id),
    INDEX idx_events_type (type),
    INDEX idx_events_created_at (created_at),
    
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE SET NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- Feature Flags
CREATE TABLE feature_flags (
    id CHAR(36) PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    enabled BOOLEAN NOT NULL DEFAULT FALSE,
    rollout_percentage TINYINT UNSIGNED DEFAULT 0,
    allowed_organizations JSON,
    metadata JSON,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_feature_flags_name (name),
    INDEX idx_feature_flags_enabled (enabled),
    
    CONSTRAINT chk_rollout CHECK (rollout_percentage >= 0 AND rollout_percentage <= 100)
);

-- ============================================================================
-- SEED DATA
-- ============================================================================

-- Users (20 users with realistic data)
INSERT INTO users (id, email, name, avatar_url, email_verified_at, last_login_at, created_at) VALUES
    ('a1b2c3d4-e5f6-4789-abcd-111111111111', 'sarah.chen@gmail.com', 'Sarah Chen', 'https://api.dicebear.com/7.x/avataaars/svg?seed=sarah', DATE_SUB(NOW(), INTERVAL 89 DAY), DATE_SUB(NOW(), INTERVAL 2 HOUR), DATE_SUB(NOW(), INTERVAL 90 DAY)),
    ('a1b2c3d4-e5f6-4789-abcd-222222222222', 'marcus.johnson@outlook.com', 'Marcus Johnson', 'https://api.dicebear.com/7.x/avataaars/svg?seed=marcus', DATE_SUB(NOW(), INTERVAL 84 DAY), DATE_SUB(NOW(), INTERVAL 1 DAY), DATE_SUB(NOW(), INTERVAL 85 DAY)),
    ('a1b2c3d4-e5f6-4789-abcd-333333333333', 'priya.patel@company.io', 'Priya Patel', 'https://api.dicebear.com/7.x/avataaars/svg?seed=priya', DATE_SUB(NOW(), INTERVAL 79 DAY), DATE_SUB(NOW(), INTERVAL 5 HOUR), DATE_SUB(NOW(), INTERVAL 80 DAY)),
    ('a1b2c3d4-e5f6-4789-abcd-444444444444', 'alex.rivera@techstartup.com', 'Alex Rivera', NULL, DATE_SUB(NOW(), INTERVAL 59 DAY), DATE_SUB(NOW(), INTERVAL 3 DAY), DATE_SUB(NOW(), INTERVAL 60 DAY)),
    ('a1b2c3d4-e5f6-4789-abcd-555555555555', 'emma.wilson@agency.co', 'Emma Wilson', 'https://api.dicebear.com/7.x/avataaars/svg?seed=emma', DATE_SUB(NOW(), INTERVAL 44 DAY), DATE_SUB(NOW(), INTERVAL 12 HOUR), DATE_SUB(NOW(), INTERVAL 45 DAY)),
    ('a1b2c3d4-e5f6-4789-abcd-666666666666', 'james.kim@devhouse.io', 'James Kim', 'https://api.dicebear.com/7.x/avataaars/svg?seed=james', DATE_SUB(NOW(), INTERVAL 39 DAY), DATE_SUB(NOW(), INTERVAL 6 HOUR), DATE_SUB(NOW(), INTERVAL 40 DAY)),
    ('a1b2c3d4-e5f6-4789-abcd-777777777777', 'olivia.martinez@freelance.dev', 'Olivia Martinez', NULL, NULL, DATE_SUB(NOW(), INTERVAL 7 DAY), DATE_SUB(NOW(), INTERVAL 35 DAY)),
    ('a1b2c3d4-e5f6-4789-abcd-888888888888', 'david.thompson@bigcorp.com', 'David Thompson', 'https://api.dicebear.com/7.x/avataaars/svg?seed=david', DATE_SUB(NOW(), INTERVAL 29 DAY), DATE_SUB(NOW(), INTERVAL 4 HOUR), DATE_SUB(NOW(), INTERVAL 30 DAY)),
    ('a1b2c3d4-e5f6-4789-abcd-999999999999', 'sofia.andersson@nordic.tech', 'Sofia Andersson', 'https://api.dicebear.com/7.x/avataaars/svg?seed=sofia', DATE_SUB(NOW(), INTERVAL 24 DAY), DATE_SUB(NOW(), INTERVAL 2 DAY), DATE_SUB(NOW(), INTERVAL 25 DAY)),
    ('a1b2c3d4-e5f6-4789-abcd-aaaaaaaaaaaa', 'ryan.ogrady@startup.ie', 'Ryan O\'Grady', 'https://api.dicebear.com/7.x/avataaars/svg?seed=ryan', DATE_SUB(NOW(), INTERVAL 19 DAY), DATE_SUB(NOW(), INTERVAL 8 HOUR), DATE_SUB(NOW(), INTERVAL 20 DAY)),
    ('a1b2c3d4-e5f6-4789-abcd-bbbbbbbbbbbb', 'mei.zhang@enterprise.cn', 'Mei Zhang', 'https://api.dicebear.com/7.x/avataaars/svg?seed=mei', DATE_SUB(NOW(), INTERVAL 14 DAY), DATE_SUB(NOW(), INTERVAL 1 HOUR), DATE_SUB(NOW(), INTERVAL 15 DAY)),
    ('a1b2c3d4-e5f6-4789-abcd-cccccccccccc', 'lucas.fernandez@latam.io', 'Lucas Fernandez', NULL, DATE_SUB(NOW(), INTERVAL 9 DAY), DATE_SUB(NOW(), INTERVAL 16 HOUR), DATE_SUB(NOW(), INTERVAL 10 DAY)),
    ('a1b2c3d4-e5f6-4789-abcd-dddddddddddd', 'anna.kowalski@polish.dev', 'Anna Kowalski', 'https://api.dicebear.com/7.x/avataaars/svg?seed=anna', DATE_SUB(NOW(), INTERVAL 7 DAY), DATE_SUB(NOW(), INTERVAL 3 HOUR), DATE_SUB(NOW(), INTERVAL 8 DAY)),
    ('a1b2c3d4-e5f6-4789-abcd-eeeeeeeeeeee', 'tom.nguyen@saigon.tech', 'Tom Nguyen', 'https://api.dicebear.com/7.x/avataaars/svg?seed=tom', DATE_SUB(NOW(), INTERVAL 6 DAY), DATE_SUB(NOW(), INTERVAL 45 MINUTE), DATE_SUB(NOW(), INTERVAL 7 DAY)),
    ('a1b2c3d4-e5f6-4789-abcd-ffffffffffff', 'lisa.jackson@remote.work', 'Lisa Jackson', 'https://api.dicebear.com/7.x/avataaars/svg?seed=lisa', DATE_SUB(NOW(), INTERVAL 4 DAY), DATE_SUB(NOW(), INTERVAL 20 HOUR), DATE_SUB(NOW(), INTERVAL 5 DAY)),
    ('b1b2c3d4-e5f6-4789-abcd-111111111111', 'ahmed.hassan@cairo.dev', 'Ahmed Hassan', NULL, NULL, NULL, DATE_SUB(NOW(), INTERVAL 4 DAY)),
    ('b1b2c3d4-e5f6-4789-abcd-222222222222', 'nina.volkov@moscow.io', 'Nina Volkov', 'https://api.dicebear.com/7.x/avataaars/svg?seed=nina', DATE_SUB(NOW(), INTERVAL 2 DAY), DATE_SUB(NOW(), INTERVAL 5 HOUR), DATE_SUB(NOW(), INTERVAL 3 DAY)),
    ('b1b2c3d4-e5f6-4789-abcd-333333333333', 'chris.baker@london.agency', 'Chris Baker', 'https://api.dicebear.com/7.x/avataaars/svg?seed=chris', DATE_SUB(NOW(), INTERVAL 1 DAY), DATE_SUB(NOW(), INTERVAL 30 MINUTE), DATE_SUB(NOW(), INTERVAL 2 DAY)),
    ('b1b2c3d4-e5f6-4789-abcd-444444444444', 'yuki.tanaka@tokyo.tech', 'Yuki Tanaka', 'https://api.dicebear.com/7.x/avataaars/svg?seed=yuki', DATE_SUB(NOW(), INTERVAL 12 HOUR), DATE_SUB(NOW(), INTERVAL 2 HOUR), DATE_SUB(NOW(), INTERVAL 1 DAY)),
    ('b1b2c3d4-e5f6-4789-abcd-555555555555', 'fatima.ali@dubai.startup', 'Fatima Ali', NULL, NULL, NULL, DATE_SUB(NOW(), INTERVAL 6 HOUR));

-- Organizations (8 organizations with varied plans)
INSERT INTO organizations (id, name, slug, plan, logo_url, website, billing_email, metadata, created_at) VALUES
    ('c1c2c3c4-e5f6-4789-abcd-111111111111', 'Acme Corporation', 'acme-corp', 'enterprise', 'https://api.dicebear.com/7.x/identicon/svg?seed=acme', 'https://acme.example.com', 'billing@acme.example.com', '{"industry": "technology", "size": "500-1000", "region": "north-america"}', DATE_SUB(NOW(), INTERVAL 88 DAY)),
    ('c1c2c3c4-e5f6-4789-abcd-222222222222', 'Startup Labs', 'startup-labs', 'pro', 'https://api.dicebear.com/7.x/identicon/svg?seed=startuplabs', 'https://startuplabs.io', 'finance@startuplabs.io', '{"industry": "saas", "size": "10-50", "region": "europe"}', DATE_SUB(NOW(), INTERVAL 75 DAY)),
    ('c1c2c3c4-e5f6-4789-abcd-333333333333', 'DevHouse Agency', 'devhouse', 'pro', 'https://api.dicebear.com/7.x/identicon/svg?seed=devhouse', 'https://devhouse.io', NULL, '{"industry": "agency", "size": "50-100"}', DATE_SUB(NOW(), INTERVAL 60 DAY)),
    ('c1c2c3c4-e5f6-4789-abcd-444444444444', 'Nordic Tech Solutions', 'nordic-tech', 'starter', NULL, 'https://nordic-tech.se', 'accounts@nordic-tech.se', '{"industry": "consulting", "size": "10-50", "region": "europe"}', DATE_SUB(NOW(), INTERVAL 45 DAY)),
    ('c1c2c3c4-e5f6-4789-abcd-555555555555', 'Solo Developer', 'solo-dev', 'free', NULL, NULL, NULL, '{}', DATE_SUB(NOW(), INTERVAL 30 DAY)),
    ('c1c2c3c4-e5f6-4789-abcd-666666666666', 'Enterprise Global Inc', 'enterprise-global', 'enterprise', 'https://api.dicebear.com/7.x/identicon/svg?seed=enterprise', 'https://enterprise-global.com', 'ap@enterprise-global.com', '{"industry": "finance", "size": "1000+", "region": "global"}', DATE_SUB(NOW(), INTERVAL 20 DAY)),
    ('c1c2c3c4-e5f6-4789-abcd-777777777777', 'Fresh Startup', 'fresh-startup', 'starter', NULL, NULL, 'hello@freshstartup.co', '{"industry": "fintech", "size": "1-10"}', DATE_SUB(NOW(), INTERVAL 10 DAY)),
    ('c1c2c3c4-e5f6-4789-abcd-888888888888', 'Trial Company', 'trial-company', 'free', NULL, NULL, NULL, '{}', DATE_SUB(NOW(), INTERVAL 3 DAY));

-- Memberships
INSERT INTO memberships (id, user_id, organization_id, role, invited_by, joined_at) VALUES
    -- Acme Corporation (enterprise) - 6 members
    (UUID(), 'a1b2c3d4-e5f6-4789-abcd-111111111111', 'c1c2c3c4-e5f6-4789-abcd-111111111111', 'owner', NULL, DATE_SUB(NOW(), INTERVAL 88 DAY)),
    (UUID(), 'a1b2c3d4-e5f6-4789-abcd-222222222222', 'c1c2c3c4-e5f6-4789-abcd-111111111111', 'admin', 'a1b2c3d4-e5f6-4789-abcd-111111111111', DATE_SUB(NOW(), INTERVAL 85 DAY)),
    (UUID(), 'a1b2c3d4-e5f6-4789-abcd-333333333333', 'c1c2c3c4-e5f6-4789-abcd-111111111111', 'member', 'a1b2c3d4-e5f6-4789-abcd-111111111111', DATE_SUB(NOW(), INTERVAL 80 DAY)),
    (UUID(), 'a1b2c3d4-e5f6-4789-abcd-888888888888', 'c1c2c3c4-e5f6-4789-abcd-111111111111', 'member', 'a1b2c3d4-e5f6-4789-abcd-222222222222', DATE_SUB(NOW(), INTERVAL 30 DAY)),
    (UUID(), 'a1b2c3d4-e5f6-4789-abcd-bbbbbbbbbbbb', 'c1c2c3c4-e5f6-4789-abcd-111111111111', 'viewer', 'a1b2c3d4-e5f6-4789-abcd-222222222222', DATE_SUB(NOW(), INTERVAL 15 DAY)),
    (UUID(), 'b1b2c3d4-e5f6-4789-abcd-333333333333', 'c1c2c3c4-e5f6-4789-abcd-111111111111', 'member', 'a1b2c3d4-e5f6-4789-abcd-111111111111', DATE_SUB(NOW(), INTERVAL 2 DAY)),
    
    -- Startup Labs (pro) - 4 members
    (UUID(), 'a1b2c3d4-e5f6-4789-abcd-444444444444', 'c1c2c3c4-e5f6-4789-abcd-222222222222', 'owner', NULL, DATE_SUB(NOW(), INTERVAL 75 DAY)),
    (UUID(), 'a1b2c3d4-e5f6-4789-abcd-555555555555', 'c1c2c3c4-e5f6-4789-abcd-222222222222', 'admin', 'a1b2c3d4-e5f6-4789-abcd-444444444444', DATE_SUB(NOW(), INTERVAL 45 DAY)),
    (UUID(), 'a1b2c3d4-e5f6-4789-abcd-cccccccccccc', 'c1c2c3c4-e5f6-4789-abcd-222222222222', 'member', 'a1b2c3d4-e5f6-4789-abcd-444444444444', DATE_SUB(NOW(), INTERVAL 10 DAY)),
    (UUID(), 'b1b2c3d4-e5f6-4789-abcd-444444444444', 'c1c2c3c4-e5f6-4789-abcd-222222222222', 'member', 'a1b2c3d4-e5f6-4789-abcd-555555555555', DATE_SUB(NOW(), INTERVAL 1 DAY)),
    
    -- DevHouse Agency (pro) - 3 members
    (UUID(), 'a1b2c3d4-e5f6-4789-abcd-666666666666', 'c1c2c3c4-e5f6-4789-abcd-333333333333', 'owner', NULL, DATE_SUB(NOW(), INTERVAL 60 DAY)),
    (UUID(), 'a1b2c3d4-e5f6-4789-abcd-777777777777', 'c1c2c3c4-e5f6-4789-abcd-333333333333', 'admin', 'a1b2c3d4-e5f6-4789-abcd-666666666666', DATE_SUB(NOW(), INTERVAL 35 DAY)),
    (UUID(), 'a1b2c3d4-e5f6-4789-abcd-dddddddddddd', 'c1c2c3c4-e5f6-4789-abcd-333333333333', 'member', 'a1b2c3d4-e5f6-4789-abcd-666666666666', DATE_SUB(NOW(), INTERVAL 8 DAY)),
    
    -- Nordic Tech Solutions (starter) - 2 members
    (UUID(), 'a1b2c3d4-e5f6-4789-abcd-999999999999', 'c1c2c3c4-e5f6-4789-abcd-444444444444', 'owner', NULL, DATE_SUB(NOW(), INTERVAL 45 DAY)),
    (UUID(), 'a1b2c3d4-e5f6-4789-abcd-aaaaaaaaaaaa', 'c1c2c3c4-e5f6-4789-abcd-444444444444', 'member', 'a1b2c3d4-e5f6-4789-abcd-999999999999', DATE_SUB(NOW(), INTERVAL 20 DAY)),
    
    -- Solo Developer (free) - 1 member
    (UUID(), 'a1b2c3d4-e5f6-4789-abcd-eeeeeeeeeeee', 'c1c2c3c4-e5f6-4789-abcd-555555555555', 'owner', NULL, DATE_SUB(NOW(), INTERVAL 30 DAY)),
    
    -- Enterprise Global (enterprise) - 4 members
    (UUID(), 'a1b2c3d4-e5f6-4789-abcd-ffffffffffff', 'c1c2c3c4-e5f6-4789-abcd-666666666666', 'owner', NULL, DATE_SUB(NOW(), INTERVAL 20 DAY)),
    (UUID(), 'b1b2c3d4-e5f6-4789-abcd-111111111111', 'c1c2c3c4-e5f6-4789-abcd-666666666666', 'admin', 'a1b2c3d4-e5f6-4789-abcd-ffffffffffff', DATE_SUB(NOW(), INTERVAL 4 DAY)),
    (UUID(), 'b1b2c3d4-e5f6-4789-abcd-222222222222', 'c1c2c3c4-e5f6-4789-abcd-666666666666', 'member', 'a1b2c3d4-e5f6-4789-abcd-ffffffffffff', DATE_SUB(NOW(), INTERVAL 3 DAY)),
    (UUID(), 'b1b2c3d4-e5f6-4789-abcd-555555555555', 'c1c2c3c4-e5f6-4789-abcd-666666666666', 'viewer', 'b1b2c3d4-e5f6-4789-abcd-111111111111', DATE_SUB(NOW(), INTERVAL 6 HOUR)),
    
    -- Fresh Startup (starter) - 2 members  
    (UUID(), 'a1b2c3d4-e5f6-4789-abcd-cccccccccccc', 'c1c2c3c4-e5f6-4789-abcd-777777777777', 'owner', NULL, DATE_SUB(NOW(), INTERVAL 10 DAY)),
    (UUID(), 'a1b2c3d4-e5f6-4789-abcd-dddddddddddd', 'c1c2c3c4-e5f6-4789-abcd-777777777777', 'admin', 'a1b2c3d4-e5f6-4789-abcd-cccccccccccc', DATE_SUB(NOW(), INTERVAL 5 DAY)),
    
    -- Trial Company (free) - 1 member
    (UUID(), 'b1b2c3d4-e5f6-4789-abcd-444444444444', 'c1c2c3c4-e5f6-4789-abcd-888888888888', 'owner', NULL, DATE_SUB(NOW(), INTERVAL 3 DAY));

-- Projects (15 projects across organizations)
INSERT INTO projects (id, organization_id, name, description, status, settings, created_by, created_at) VALUES
    -- Acme Corporation projects
    ('d1d2d3d4-e5f6-4789-abcd-111111111111', 'c1c2c3c4-e5f6-4789-abcd-111111111111', 'Customer Portal', 'Main customer-facing web application', 'active', '{"environment": "production", "framework": "next.js"}', 'a1b2c3d4-e5f6-4789-abcd-111111111111', DATE_SUB(NOW(), INTERVAL 87 DAY)),
    ('d1d2d3d4-e5f6-4789-abcd-222222222222', 'c1c2c3c4-e5f6-4789-abcd-111111111111', 'Internal Dashboard', 'Admin tools and analytics', 'active', '{"environment": "production", "framework": "react"}', 'a1b2c3d4-e5f6-4789-abcd-222222222222', DATE_SUB(NOW(), INTERVAL 80 DAY)),
    ('d1d2d3d4-e5f6-4789-abcd-333333333333', 'c1c2c3c4-e5f6-4789-abcd-111111111111', 'Mobile App v2', 'React Native mobile application', 'active', '{"environment": "staging", "framework": "react-native"}', 'a1b2c3d4-e5f6-4789-abcd-333333333333', DATE_SUB(NOW(), INTERVAL 45 DAY)),
    ('d1d2d3d4-e5f6-4789-abcd-444444444444', 'c1c2c3c4-e5f6-4789-abcd-111111111111', 'Legacy API', 'Deprecated REST API (sunset Q2 2024)', 'paused', '{"environment": "production", "deprecated": true}', 'a1b2c3d4-e5f6-4789-abcd-111111111111', DATE_SUB(NOW(), INTERVAL 300 DAY)),
    ('d1d2d3d4-e5f6-4789-abcd-555555555555', 'c1c2c3c4-e5f6-4789-abcd-111111111111', 'Data Pipeline', NULL, 'archived', '{}', 'a1b2c3d4-e5f6-4789-abcd-222222222222', DATE_SUB(NOW(), INTERVAL 200 DAY)),
    
    -- Startup Labs projects
    ('d1d2d3d4-e5f6-4789-abcd-666666666666', 'c1c2c3c4-e5f6-4789-abcd-222222222222', 'SaaS Platform', 'Core product platform', 'active', '{"environment": "production"}', 'a1b2c3d4-e5f6-4789-abcd-444444444444', DATE_SUB(NOW(), INTERVAL 74 DAY)),
    ('d1d2d3d4-e5f6-4789-abcd-777777777777', 'c1c2c3c4-e5f6-4789-abcd-222222222222', 'Marketing Site', 'Public website and blog', 'active', '{"environment": "production", "cms": "contentful"}', 'a1b2c3d4-e5f6-4789-abcd-555555555555', DATE_SUB(NOW(), INTERVAL 50 DAY)),
    ('d1d2d3d4-e5f6-4789-abcd-888888888888', 'c1c2c3c4-e5f6-4789-abcd-222222222222', 'Analytics Service', 'Internal metrics and tracking', 'active', '{}', 'a1b2c3d4-e5f6-4789-abcd-444444444444', DATE_SUB(NOW(), INTERVAL 30 DAY)),
    
    -- DevHouse Agency projects
    ('d1d2d3d4-e5f6-4789-abcd-999999999999', 'c1c2c3c4-e5f6-4789-abcd-333333333333', 'Client: TechCorp', 'E-commerce platform build', 'active', '{"client": "techcorp", "deadline": "2024-06-30"}', 'a1b2c3d4-e5f6-4789-abcd-666666666666', DATE_SUB(NOW(), INTERVAL 55 DAY)),
    ('d1d2d3d4-e5f6-4789-abcd-aaaaaaaaaaaa', 'c1c2c3c4-e5f6-4789-abcd-333333333333', 'Client: HealthApp', 'Healthcare mobile app', 'active', '{"client": "healthapp"}', 'a1b2c3d4-e5f6-4789-abcd-777777777777', DATE_SUB(NOW(), INTERVAL 20 DAY)),
    ('d1d2d3d4-e5f6-4789-abcd-bbbbbbbbbbbb', 'c1c2c3c4-e5f6-4789-abcd-333333333333', 'Client: OldBank', 'Legacy system maintenance', 'archived', '{"client": "oldbank", "archived_reason": "contract_ended"}', 'a1b2c3d4-e5f6-4789-abcd-666666666666', DATE_SUB(NOW(), INTERVAL 180 DAY)),
    
    -- Nordic Tech Solutions
    ('d1d2d3d4-e5f6-4789-abcd-cccccccccccc', 'c1c2c3c4-e5f6-4789-abcd-444444444444', 'Consulting Tools', 'Internal tooling suite', 'active', '{}', 'a1b2c3d4-e5f6-4789-abcd-999999999999', DATE_SUB(NOW(), INTERVAL 40 DAY)),
    
    -- Solo Developer
    ('d1d2d3d4-e5f6-4789-abcd-dddddddddddd', 'c1c2c3c4-e5f6-4789-abcd-555555555555', 'Side Project', 'Personal SaaS experiment', 'active', '{"personal": true}', 'a1b2c3d4-e5f6-4789-abcd-eeeeeeeeeeee', DATE_SUB(NOW(), INTERVAL 28 DAY)),
    
    -- Enterprise Global
    ('d1d2d3d4-e5f6-4789-abcd-eeeeeeeeeeee', 'c1c2c3c4-e5f6-4789-abcd-666666666666', 'Trading Platform', 'Real-time trading system', 'active', '{"environment": "production", "compliance": "sox"}', 'a1b2c3d4-e5f6-4789-abcd-ffffffffffff', DATE_SUB(NOW(), INTERVAL 18 DAY)),
    ('d1d2d3d4-e5f6-4789-abcd-ffffffffffff', 'c1c2c3c4-e5f6-4789-abcd-666666666666', 'Risk Analytics', 'Risk assessment dashboard', 'active', '{"environment": "staging"}', 'b1b2c3d4-e5f6-4789-abcd-111111111111', DATE_SUB(NOW(), INTERVAL 3 DAY));

-- API Keys
INSERT INTO api_keys (id, organization_id, name, key_prefix, key_hash, scopes, last_used_at, expires_at, created_by, created_at, revoked_at) VALUES
    -- Acme Corporation
    ('e1e2e3e4-e5f6-4789-abcd-111111111111', 'c1c2c3c4-e5f6-4789-abcd-111111111111', 'Production API', 'pk_live_acm', 'sha256$a1b2c3d4e5f6g7h8i9j0...', '["read", "write"]', DATE_SUB(NOW(), INTERVAL 5 MINUTE), DATE_ADD(NOW(), INTERVAL 1 YEAR), 'a1b2c3d4-e5f6-4789-abcd-111111111111', DATE_SUB(NOW(), INTERVAL 85 DAY), NULL),
    ('e1e2e3e4-e5f6-4789-abcd-222222222222', 'c1c2c3c4-e5f6-4789-abcd-111111111111', 'Staging API', 'pk_test_acm', 'sha256$b2c3d4e5f6g7h8i9j0k1...', '["read", "write", "delete"]', DATE_SUB(NOW(), INTERVAL 2 HOUR), NULL, 'a1b2c3d4-e5f6-4789-abcd-222222222222', DATE_SUB(NOW(), INTERVAL 80 DAY), NULL),
    ('e1e2e3e4-e5f6-4789-abcd-333333333333', 'c1c2c3c4-e5f6-4789-abcd-111111111111', 'CI/CD Pipeline', 'pk_ci_acme', 'sha256$c3d4e5f6g7h8i9j0k1l2...', '["read"]', DATE_SUB(NOW(), INTERVAL 1 DAY), DATE_ADD(NOW(), INTERVAL 90 DAY), 'a1b2c3d4-e5f6-4789-abcd-333333333333', DATE_SUB(NOW(), INTERVAL 60 DAY), NULL),
    ('e1e2e3e4-e5f6-4789-abcd-444444444444', 'c1c2c3c4-e5f6-4789-abcd-111111111111', 'Old Integration', 'pk_old_acme', 'sha256$d4e5f6g7h8i9j0k1l2m3...', '["read"]', DATE_SUB(NOW(), INTERVAL 180 DAY), DATE_SUB(NOW(), INTERVAL 30 DAY), 'a1b2c3d4-e5f6-4789-abcd-111111111111', DATE_SUB(NOW(), INTERVAL 365 DAY), DATE_SUB(NOW(), INTERVAL 30 DAY)),
    
    -- Startup Labs
    ('e1e2e3e4-e5f6-4789-abcd-555555555555', 'c1c2c3c4-e5f6-4789-abcd-222222222222', 'Main API Key', 'pk_live_stl', 'sha256$e5f6g7h8i9j0k1l2m3n4...', '["read", "write"]', DATE_SUB(NOW(), INTERVAL 30 MINUTE), NULL, 'a1b2c3d4-e5f6-4789-abcd-444444444444', DATE_SUB(NOW(), INTERVAL 70 DAY), NULL),
    ('e1e2e3e4-e5f6-4789-abcd-666666666666', 'c1c2c3c4-e5f6-4789-abcd-222222222222', 'Webhook Service', 'pk_whk_stl', 'sha256$f6g7h8i9j0k1l2m3n4o5...', '["read"]', DATE_SUB(NOW(), INTERVAL 4 HOUR), NULL, 'a1b2c3d4-e5f6-4789-abcd-555555555555', DATE_SUB(NOW(), INTERVAL 45 DAY), NULL),
    
    -- DevHouse Agency
    ('e1e2e3e4-e5f6-4789-abcd-777777777777', 'c1c2c3c4-e5f6-4789-abcd-333333333333', 'Client Projects', 'pk_live_dvh', 'sha256$g7h8i9j0k1l2m3n4o5p6...', '["read", "write", "delete"]', DATE_SUB(NOW(), INTERVAL 12 HOUR), NULL, 'a1b2c3d4-e5f6-4789-abcd-666666666666', DATE_SUB(NOW(), INTERVAL 55 DAY), NULL),
    
    -- Enterprise Global
    ('e1e2e3e4-e5f6-4789-abcd-888888888888', 'c1c2c3c4-e5f6-4789-abcd-666666666666', 'Trading API', 'pk_live_ent', 'sha256$h8i9j0k1l2m3n4o5p6q7...', '["read", "write", "trade"]', DATE_SUB(NOW(), INTERVAL 2 MINUTE), NULL, 'a1b2c3d4-e5f6-4789-abcd-ffffffffffff', DATE_SUB(NOW(), INTERVAL 15 DAY), NULL),
    ('e1e2e3e4-e5f6-4789-abcd-999999999999', 'c1c2c3c4-e5f6-4789-abcd-666666666666', 'Read-Only Analytics', 'pk_ro_ent', 'sha256$i9j0k1l2m3n4o5p6q7r8...', '["read"]', NULL, NULL, 'b1b2c3d4-e5f6-4789-abcd-111111111111', DATE_SUB(NOW(), INTERVAL 3 DAY), NULL);

-- Subscriptions
INSERT INTO subscriptions (id, organization_id, plan, status, stripe_subscription_id, stripe_customer_id, current_period_start, current_period_end, cancel_at, canceled_at, trial_end, created_at) VALUES
    -- Acme Corporation - Enterprise (active)
    ('f1f2f3f4-e5f6-4789-abcd-111111111111', 'c1c2c3c4-e5f6-4789-abcd-111111111111', 'enterprise', 'active', 'sub_1NxYz123456789', 'cus_AcmeCorp001', DATE_SUB(NOW(), INTERVAL 28 DAY), DATE_ADD(NOW(), INTERVAL 2 DAY), NULL, NULL, NULL, DATE_SUB(NOW(), INTERVAL 88 DAY)),
    
    -- Startup Labs - Pro (active)
    ('f1f2f3f4-e5f6-4789-abcd-222222222222', 'c1c2c3c4-e5f6-4789-abcd-222222222222', 'pro', 'active', 'sub_2AbCd234567890', 'cus_StartupLabs01', DATE_SUB(NOW(), INTERVAL 15 DAY), DATE_ADD(NOW(), INTERVAL 15 DAY), NULL, NULL, NULL, DATE_SUB(NOW(), INTERVAL 75 DAY)),
    
    -- DevHouse Agency - Pro (past_due)
    ('f1f2f3f4-e5f6-4789-abcd-333333333333', 'c1c2c3c4-e5f6-4789-abcd-333333333333', 'pro', 'past_due', 'sub_3CdEf345678901', 'cus_DevHouse0001', DATE_SUB(NOW(), INTERVAL 35 DAY), DATE_SUB(NOW(), INTERVAL 5 DAY), NULL, NULL, NULL, DATE_SUB(NOW(), INTERVAL 60 DAY)),
    
    -- Nordic Tech Solutions - Starter (active)
    ('f1f2f3f4-e5f6-4789-abcd-444444444444', 'c1c2c3c4-e5f6-4789-abcd-444444444444', 'starter', 'active', 'sub_4EfGh456789012', 'cus_NordicTech01', DATE_SUB(NOW(), INTERVAL 10 DAY), DATE_ADD(NOW(), INTERVAL 20 DAY), NULL, NULL, NULL, DATE_SUB(NOW(), INTERVAL 45 DAY)),
    
    -- Enterprise Global - Enterprise (active)
    ('f1f2f3f4-e5f6-4789-abcd-555555555555', 'c1c2c3c4-e5f6-4789-abcd-666666666666', 'enterprise', 'active', 'sub_5GhIj567890123', 'cus_EntGlobal001', DATE_SUB(NOW(), INTERVAL 5 DAY), DATE_ADD(NOW(), INTERVAL 25 DAY), NULL, NULL, NULL, DATE_SUB(NOW(), INTERVAL 20 DAY)),
    
    -- Fresh Startup - Starter (trialing)
    ('f1f2f3f4-e5f6-4789-abcd-666666666666', 'c1c2c3c4-e5f6-4789-abcd-777777777777', 'starter', 'trialing', 'sub_6IjKl678901234', 'cus_FreshStart01', DATE_SUB(NOW(), INTERVAL 10 DAY), DATE_ADD(NOW(), INTERVAL 20 DAY), NULL, NULL, DATE_ADD(NOW(), INTERVAL 4 DAY), DATE_SUB(NOW(), INTERVAL 10 DAY)),
    
    -- Trial Company - Canceled subscription (for history)
    ('f1f2f3f4-e5f6-4789-abcd-777777777777', 'c1c2c3c4-e5f6-4789-abcd-888888888888', 'starter', 'canceled', 'sub_7KlMn789012345', 'cus_TrialCo00001', DATE_SUB(NOW(), INTERVAL 30 DAY), DATE_SUB(NOW(), INTERVAL 2 DAY), DATE_SUB(NOW(), INTERVAL 2 DAY), DATE_SUB(NOW(), INTERVAL 5 DAY), NULL, DATE_SUB(NOW(), INTERVAL 30 DAY));

-- Invoices
INSERT INTO invoices (id, organization_id, subscription_id, stripe_invoice_id, amount_cents, currency, status, description, invoice_url, due_date, paid_at, created_at) VALUES
    -- Acme Corporation invoices
    ('11111111-e5f6-4789-abcd-111111111111', 'c1c2c3c4-e5f6-4789-abcd-111111111111', 'f1f2f3f4-e5f6-4789-abcd-111111111111', 'in_acme_001', 99900, 'USD', 'paid', 'Enterprise Plan - Monthly', 'https://invoice.stripe.com/i/acme_001', DATE_SUB(NOW(), INTERVAL 58 DAY), DATE_SUB(NOW(), INTERVAL 57 DAY), DATE_SUB(NOW(), INTERVAL 60 DAY)),
    ('11111111-e5f6-4789-abcd-222222222222', 'c1c2c3c4-e5f6-4789-abcd-111111111111', 'f1f2f3f4-e5f6-4789-abcd-111111111111', 'in_acme_002', 99900, 'USD', 'paid', 'Enterprise Plan - Monthly', 'https://invoice.stripe.com/i/acme_002', DATE_SUB(NOW(), INTERVAL 28 DAY), DATE_SUB(NOW(), INTERVAL 27 DAY), DATE_SUB(NOW(), INTERVAL 30 DAY)),
    ('11111111-e5f6-4789-abcd-333333333333', 'c1c2c3c4-e5f6-4789-abcd-111111111111', 'f1f2f3f4-e5f6-4789-abcd-111111111111', 'in_acme_003', 99900, 'USD', 'pending', 'Enterprise Plan - Monthly', 'https://invoice.stripe.com/i/acme_003', DATE_ADD(NOW(), INTERVAL 2 DAY), NULL, NOW()),
    
    -- Startup Labs invoices
    ('11111111-e5f6-4789-abcd-444444444444', 'c1c2c3c4-e5f6-4789-abcd-222222222222', 'f1f2f3f4-e5f6-4789-abcd-222222222222', 'in_stl_001', 4900, 'USD', 'paid', 'Pro Plan - Monthly', 'https://invoice.stripe.com/i/stl_001', DATE_SUB(NOW(), INTERVAL 45 DAY), DATE_SUB(NOW(), INTERVAL 45 DAY), DATE_SUB(NOW(), INTERVAL 45 DAY)),
    ('11111111-e5f6-4789-abcd-555555555555', 'c1c2c3c4-e5f6-4789-abcd-222222222222', 'f1f2f3f4-e5f6-4789-abcd-222222222222', 'in_stl_002', 4900, 'USD', 'paid', 'Pro Plan - Monthly', 'https://invoice.stripe.com/i/stl_002', DATE_SUB(NOW(), INTERVAL 15 DAY), DATE_SUB(NOW(), INTERVAL 14 DAY), DATE_SUB(NOW(), INTERVAL 15 DAY)),
    
    -- DevHouse Agency invoices (one failed)
    ('11111111-e5f6-4789-abcd-666666666666', 'c1c2c3c4-e5f6-4789-abcd-333333333333', 'f1f2f3f4-e5f6-4789-abcd-333333333333', 'in_dvh_001', 4900, 'USD', 'paid', 'Pro Plan - Monthly', 'https://invoice.stripe.com/i/dvh_001', DATE_SUB(NOW(), INTERVAL 35 DAY), DATE_SUB(NOW(), INTERVAL 34 DAY), DATE_SUB(NOW(), INTERVAL 35 DAY)),
    ('11111111-e5f6-4789-abcd-777777777777', 'c1c2c3c4-e5f6-4789-abcd-333333333333', 'f1f2f3f4-e5f6-4789-abcd-333333333333', 'in_dvh_002', 4900, 'USD', 'failed', 'Pro Plan - Monthly', 'https://invoice.stripe.com/i/dvh_002', DATE_SUB(NOW(), INTERVAL 5 DAY), NULL, DATE_SUB(NOW(), INTERVAL 5 DAY)),
    
    -- Nordic Tech Solutions
    ('11111111-e5f6-4789-abcd-888888888888', 'c1c2c3c4-e5f6-4789-abcd-444444444444', 'f1f2f3f4-e5f6-4789-abcd-444444444444', 'in_nts_001', 1900, 'USD', 'paid', 'Starter Plan - Monthly', 'https://invoice.stripe.com/i/nts_001', DATE_SUB(NOW(), INTERVAL 10 DAY), DATE_SUB(NOW(), INTERVAL 10 DAY), DATE_SUB(NOW(), INTERVAL 10 DAY)),
    
    -- Enterprise Global
    ('11111111-e5f6-4789-abcd-999999999999', 'c1c2c3c4-e5f6-4789-abcd-666666666666', 'f1f2f3f4-e5f6-4789-abcd-555555555555', 'in_ent_001', 99900, 'USD', 'paid', 'Enterprise Plan - Monthly', 'https://invoice.stripe.com/i/ent_001', DATE_SUB(NOW(), INTERVAL 5 DAY), DATE_SUB(NOW(), INTERVAL 4 DAY), DATE_SUB(NOW(), INTERVAL 5 DAY)),
    
    -- Refunded invoice example
    ('11111111-e5f6-4789-abcd-aaaaaaaaaaaa', 'c1c2c3c4-e5f6-4789-abcd-888888888888', 'f1f2f3f4-e5f6-4789-abcd-777777777777', 'in_trial_001', 1900, 'USD', 'refunded', 'Starter Plan - Monthly (Refunded)', 'https://invoice.stripe.com/i/trial_001', DATE_SUB(NOW(), INTERVAL 30 DAY), DATE_SUB(NOW(), INTERVAL 29 DAY), DATE_SUB(NOW(), INTERVAL 30 DAY));

-- Events (audit log)
INSERT INTO events (id, organization_id, user_id, type, resource_type, resource_id, payload, ip_address, user_agent, created_at) VALUES
    -- User signups
    ('22222222-e5f6-4789-abcd-111111111111', NULL, 'a1b2c3d4-e5f6-4789-abcd-111111111111', 'user.created', 'user', 'a1b2c3d4-e5f6-4789-abcd-111111111111', '{"email": "sarah.chen@gmail.com"}', '73.162.214.130', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)', DATE_SUB(NOW(), INTERVAL 90 DAY)),
    ('22222222-e5f6-4789-abcd-222222222222', NULL, 'b1b2c3d4-e5f6-4789-abcd-444444444444', 'user.created', 'user', 'b1b2c3d4-e5f6-4789-abcd-444444444444', '{"email": "yuki.tanaka@tokyo.tech"}', '103.5.140.219', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)', DATE_SUB(NOW(), INTERVAL 1 DAY)),
    ('22222222-e5f6-4789-abcd-333333333333', NULL, 'b1b2c3d4-e5f6-4789-abcd-555555555555', 'user.created', 'user', 'b1b2c3d4-e5f6-4789-abcd-555555555555', '{"email": "fatima.ali@dubai.startup"}', '94.56.229.180', 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0)', DATE_SUB(NOW(), INTERVAL 6 HOUR)),
    
    -- Organization creation
    ('22222222-e5f6-4789-abcd-444444444444', 'c1c2c3c4-e5f6-4789-abcd-111111111111', 'a1b2c3d4-e5f6-4789-abcd-111111111111', 'org.created', 'organization', 'c1c2c3c4-e5f6-4789-abcd-111111111111', '{"name": "Acme Corporation", "plan": "free"}', '73.162.214.130', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)', DATE_SUB(NOW(), INTERVAL 88 DAY)),
    ('22222222-e5f6-4789-abcd-555555555555', 'c1c2c3c4-e5f6-4789-abcd-888888888888', 'b1b2c3d4-e5f6-4789-abcd-444444444444', 'org.created', 'organization', 'c1c2c3c4-e5f6-4789-abcd-888888888888', '{"name": "Trial Company", "plan": "free"}', '103.5.140.219', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)', DATE_SUB(NOW(), INTERVAL 3 DAY)),
    
    -- Project creation
    ('22222222-e5f6-4789-abcd-666666666666', 'c1c2c3c4-e5f6-4789-abcd-111111111111', 'a1b2c3d4-e5f6-4789-abcd-111111111111', 'project.created', 'project', 'd1d2d3d4-e5f6-4789-abcd-111111111111', '{"name": "Customer Portal"}', '73.162.214.130', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)', DATE_SUB(NOW(), INTERVAL 87 DAY)),
    ('22222222-e5f6-4789-abcd-777777777777', 'c1c2c3c4-e5f6-4789-abcd-666666666666', 'b1b2c3d4-e5f6-4789-abcd-111111111111', 'project.created', 'project', 'd1d2d3d4-e5f6-4789-abcd-ffffffffffff', '{"name": "Risk Analytics"}', '185.45.12.89', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)', DATE_SUB(NOW(), INTERVAL 3 DAY)),
    
    -- Subscription events
    ('22222222-e5f6-4789-abcd-888888888888', 'c1c2c3c4-e5f6-4789-abcd-111111111111', 'a1b2c3d4-e5f6-4789-abcd-111111111111', 'subscription.started', 'subscription', 'f1f2f3f4-e5f6-4789-abcd-111111111111', '{"plan": "enterprise", "amount": 999}', '73.162.214.130', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)', DATE_SUB(NOW(), INTERVAL 88 DAY)),
    ('22222222-e5f6-4789-abcd-999999999999', 'c1c2c3c4-e5f6-4789-abcd-888888888888', 'b1b2c3d4-e5f6-4789-abcd-444444444444', 'subscription.canceled', 'subscription', 'f1f2f3f4-e5f6-4789-abcd-777777777777', '{"reason": "too_expensive", "feedback": "Will come back when we have more budget"}', '103.5.140.219', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)', DATE_SUB(NOW(), INTERVAL 5 DAY)),
    
    -- Invoice paid
    ('22222222-e5f6-4789-abcd-aaaaaaaaaaaa', 'c1c2c3c4-e5f6-4789-abcd-111111111111', NULL, 'invoice.paid', 'invoice', '11111111-e5f6-4789-abcd-222222222222', '{"amount": 999, "currency": "USD"}', NULL, NULL, DATE_SUB(NOW(), INTERVAL 27 DAY)),
    ('22222222-e5f6-4789-abcd-bbbbbbbbbbbb', 'c1c2c3c4-e5f6-4789-abcd-666666666666', NULL, 'invoice.paid', 'invoice', '11111111-e5f6-4789-abcd-999999999999', '{"amount": 999, "currency": "USD"}', NULL, NULL, DATE_SUB(NOW(), INTERVAL 4 DAY)),
    
    -- API key created
    ('22222222-e5f6-4789-abcd-cccccccccccc', 'c1c2c3c4-e5f6-4789-abcd-111111111111', 'a1b2c3d4-e5f6-4789-abcd-111111111111', 'api_key.created', 'api_key', 'e1e2e3e4-e5f6-4789-abcd-111111111111', '{"name": "Production API", "scopes": ["read", "write"]}', '73.162.214.130', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)', DATE_SUB(NOW(), INTERVAL 85 DAY)),
    ('22222222-e5f6-4789-abcd-dddddddddddd', 'c1c2c3c4-e5f6-4789-abcd-666666666666', 'a1b2c3d4-e5f6-4789-abcd-ffffffffffff', 'api_key.created', 'api_key', 'e1e2e3e4-e5f6-4789-abcd-888888888888', '{"name": "Trading API", "scopes": ["read", "write", "trade"]}', '185.45.12.89', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)', DATE_SUB(NOW(), INTERVAL 15 DAY)),
    
    -- Recent activity burst
    ('22222222-e5f6-4789-abcd-eeeeeeeeeeee', 'c1c2c3c4-e5f6-4789-abcd-111111111111', 'b1b2c3d4-e5f6-4789-abcd-333333333333', 'user.updated', 'user', 'b1b2c3d4-e5f6-4789-abcd-333333333333', '{"changes": ["avatar_url"]}', '88.120.45.67', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)', DATE_SUB(NOW(), INTERVAL 30 MINUTE));

-- Feature Flags
INSERT INTO feature_flags (id, name, description, enabled, rollout_percentage, allowed_organizations, metadata, created_at) VALUES
    ('33333333-e5f6-4789-abcd-111111111111', 'new_dashboard', 'Redesigned analytics dashboard with charts', TRUE, 100, '[]', '{"version": "2.0", "designer": "emma"}', DATE_SUB(NOW(), INTERVAL 60 DAY)),
    ('33333333-e5f6-4789-abcd-222222222222', 'ai_suggestions', 'AI-powered query suggestions in editor', TRUE, 25, '["c1c2c3c4-e5f6-4789-abcd-111111111111", "c1c2c3c4-e5f6-4789-abcd-666666666666"]', '{"model": "gpt-4", "beta": true}', DATE_SUB(NOW(), INTERVAL 30 DAY)),
    ('33333333-e5f6-4789-abcd-333333333333', 'dark_mode_v2', 'Updated dark mode color scheme', TRUE, 50, '[]', '{}', DATE_SUB(NOW(), INTERVAL 20 DAY)),
    ('33333333-e5f6-4789-abcd-444444444444', 'export_pdf', 'Export reports to PDF format', FALSE, 0, '[]', '{"status": "in_development", "eta": "2024-Q2"}', DATE_SUB(NOW(), INTERVAL 15 DAY)),
    ('33333333-e5f6-4789-abcd-555555555555', 'team_collaboration', 'Real-time collaboration features', TRUE, 10, '["c1c2c3c4-e5f6-4789-abcd-111111111111"]', '{"websocket": true}', DATE_SUB(NOW(), INTERVAL 10 DAY)),
    ('33333333-e5f6-4789-abcd-666666666666', 'sso_okta', 'Okta SSO integration', FALSE, 0, '["c1c2c3c4-e5f6-4789-abcd-666666666666"]', '{"enterprise_only": true}', DATE_SUB(NOW(), INTERVAL 5 DAY)),
    ('33333333-e5f6-4789-abcd-777777777777', 'billing_v2', 'New billing system with usage-based pricing', FALSE, 0, '[]', '{"migration_required": true}', DATE_SUB(NOW(), INTERVAL 2 DAY));

-- ============================================================================
-- HELPER VIEWS
-- ============================================================================

-- Organization summary view
CREATE VIEW organization_summary AS
SELECT 
    o.id,
    o.name,
    o.slug,
    o.plan,
    COUNT(DISTINCT m.user_id) as member_count,
    COUNT(DISTINCT CASE WHEN p.status = 'active' THEN p.id END) as project_count,
    s.status as subscription_status,
    o.created_at
FROM organizations o
LEFT JOIN memberships m ON o.id = m.organization_id
LEFT JOIN projects p ON o.id = p.organization_id
LEFT JOIN subscriptions s ON o.id = s.organization_id
GROUP BY o.id, o.name, o.slug, o.plan, s.status, o.created_at;

-- Recent activity view
CREATE VIEW recent_activity AS
SELECT 
    e.id,
    e.type,
    e.created_at,
    u.name as user_name,
    u.email as user_email,
    o.name as organization_name,
    e.payload
FROM events e
LEFT JOIN users u ON e.user_id = u.id
LEFT JOIN organizations o ON e.organization_id = o.id
ORDER BY e.created_at DESC
LIMIT 100;

-- ============================================================================
-- DONE!
-- ============================================================================
-- 
-- Summary:
--   - 20 users
--   - 8 organizations (across all plan tiers)
--   - 23 memberships
--   - 15 projects
--   - 9 API keys
--   - 7 subscriptions
--   - 10 invoices
--   - 15 events
--   - 7 feature flags
--   - 2 helper views
--
-- MySQL Version - Enjoy! 🚀
-- ============================================================================