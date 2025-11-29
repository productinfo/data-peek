-- ============================================================================
-- ACME SaaS - Sample Database for data-peek
-- ============================================================================
-- A fictional SaaS platform database with realistic structure and data.
-- Perfect for testing, demos, and screenshots.
-- ============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- ENUMS
-- ============================================================================

CREATE TYPE org_plan AS ENUM ('free', 'starter', 'pro', 'enterprise');
CREATE TYPE membership_role AS ENUM ('owner', 'admin', 'member', 'viewer');
CREATE TYPE project_status AS ENUM ('active', 'paused', 'archived', 'deleted');
CREATE TYPE subscription_status AS ENUM ('active', 'past_due', 'canceled', 'trialing');
CREATE TYPE invoice_status AS ENUM ('draft', 'pending', 'paid', 'failed', 'refunded');
CREATE TYPE event_type AS ENUM ('user.created', 'user.updated', 'org.created', 'project.created', 'subscription.started', 'subscription.canceled', 'invoice.paid', 'api_key.created');

-- ============================================================================
-- TABLES
-- ============================================================================

-- Users
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    avatar_url VARCHAR(512),
    email_verified_at TIMESTAMPTZ,
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_created_at ON users(created_at);

-- Organizations
CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) NOT NULL UNIQUE,
    plan org_plan NOT NULL DEFAULT 'free',
    logo_url VARCHAR(512),
    website VARCHAR(255),
    billing_email VARCHAR(255),
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_organizations_slug ON organizations(slug);
CREATE INDEX idx_organizations_plan ON organizations(plan);

-- Memberships (users <-> organizations)
CREATE TABLE memberships (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    role membership_role NOT NULL DEFAULT 'member',
    invited_by UUID REFERENCES users(id),
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, organization_id)
);

CREATE INDEX idx_memberships_user_id ON memberships(user_id);
CREATE INDEX idx_memberships_organization_id ON memberships(organization_id);

-- Projects
CREATE TABLE projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    status project_status NOT NULL DEFAULT 'active',
    settings JSONB DEFAULT '{}',
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_projects_organization_id ON projects(organization_id);
CREATE INDEX idx_projects_status ON projects(status);

-- API Keys
CREATE TABLE api_keys (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    key_prefix VARCHAR(12) NOT NULL,
    key_hash VARCHAR(255) NOT NULL,
    scopes TEXT[] DEFAULT ARRAY['read'],
    last_used_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    revoked_at TIMESTAMPTZ
);

CREATE INDEX idx_api_keys_organization_id ON api_keys(organization_id);
CREATE INDEX idx_api_keys_key_prefix ON api_keys(key_prefix);

-- Subscriptions
CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    plan org_plan NOT NULL,
    status subscription_status NOT NULL DEFAULT 'active',
    stripe_subscription_id VARCHAR(100),
    stripe_customer_id VARCHAR(100),
    current_period_start TIMESTAMPTZ NOT NULL,
    current_period_end TIMESTAMPTZ NOT NULL,
    cancel_at TIMESTAMPTZ,
    canceled_at TIMESTAMPTZ,
    trial_end TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_subscriptions_organization_id ON subscriptions(organization_id);
CREATE INDEX idx_subscriptions_status ON subscriptions(status);

-- Invoices
CREATE TABLE invoices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    subscription_id UUID REFERENCES subscriptions(id),
    stripe_invoice_id VARCHAR(100),
    amount_cents INTEGER NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    status invoice_status NOT NULL DEFAULT 'pending',
    description VARCHAR(500),
    invoice_url VARCHAR(512),
    pdf_url VARCHAR(512),
    due_date TIMESTAMPTZ,
    paid_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_invoices_organization_id ON invoices(organization_id);
CREATE INDEX idx_invoices_status ON invoices(status);
CREATE INDEX idx_invoices_created_at ON invoices(created_at);

-- Events (audit log / activity feed)
CREATE TABLE events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID REFERENCES organizations(id) ON DELETE SET NULL,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    type event_type NOT NULL,
    resource_type VARCHAR(50),
    resource_id UUID,
    payload JSONB DEFAULT '{}',
    ip_address INET,
    user_agent VARCHAR(500),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_events_organization_id ON events(organization_id);
CREATE INDEX idx_events_user_id ON events(user_id);
CREATE INDEX idx_events_type ON events(type);
CREATE INDEX idx_events_created_at ON events(created_at);

-- Feature Flags
CREATE TABLE feature_flags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    enabled BOOLEAN NOT NULL DEFAULT false,
    rollout_percentage INTEGER DEFAULT 0 CHECK (rollout_percentage >= 0 AND rollout_percentage <= 100),
    allowed_organizations UUID[] DEFAULT ARRAY[]::UUID[],
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_feature_flags_name ON feature_flags(name);
CREATE INDEX idx_feature_flags_enabled ON feature_flags(enabled);

-- ============================================================================
-- SEED DATA
-- ============================================================================

-- Users (20 users with realistic data)
INSERT INTO users (id, email, name, avatar_url, email_verified_at, last_login_at, created_at) VALUES
    ('a1b2c3d4-e5f6-4789-abcd-111111111111', 'sarah.chen@gmail.com', 'Sarah Chen', 'https://api.dicebear.com/7.x/avataaars/svg?seed=sarah', NOW() - INTERVAL '89 days', NOW() - INTERVAL '2 hours', NOW() - INTERVAL '90 days'),
    ('a1b2c3d4-e5f6-4789-abcd-222222222222', 'marcus.johnson@outlook.com', 'Marcus Johnson', 'https://api.dicebear.com/7.x/avataaars/svg?seed=marcus', NOW() - INTERVAL '84 days', NOW() - INTERVAL '1 day', NOW() - INTERVAL '85 days'),
    ('a1b2c3d4-e5f6-4789-abcd-333333333333', 'priya.patel@company.io', 'Priya Patel', 'https://api.dicebear.com/7.x/avataaars/svg?seed=priya', NOW() - INTERVAL '79 days', NOW() - INTERVAL '5 hours', NOW() - INTERVAL '80 days'),
    ('a1b2c3d4-e5f6-4789-abcd-444444444444', 'alex.rivera@techstartup.com', 'Alex Rivera', NULL, NOW() - INTERVAL '59 days', NOW() - INTERVAL '3 days', NOW() - INTERVAL '60 days'),
    ('a1b2c3d4-e5f6-4789-abcd-555555555555', 'emma.wilson@agency.co', 'Emma Wilson', 'https://api.dicebear.com/7.x/avataaars/svg?seed=emma', NOW() - INTERVAL '44 days', NOW() - INTERVAL '12 hours', NOW() - INTERVAL '45 days'),
    ('a1b2c3d4-e5f6-4789-abcd-666666666666', 'james.kim@devhouse.io', 'James Kim', 'https://api.dicebear.com/7.x/avataaars/svg?seed=james', NOW() - INTERVAL '39 days', NOW() - INTERVAL '6 hours', NOW() - INTERVAL '40 days'),
    ('a1b2c3d4-e5f6-4789-abcd-777777777777', 'olivia.martinez@freelance.dev', 'Olivia Martinez', NULL, NULL, NOW() - INTERVAL '7 days', NOW() - INTERVAL '35 days'),
    ('a1b2c3d4-e5f6-4789-abcd-888888888888', 'david.thompson@bigcorp.com', 'David Thompson', 'https://api.dicebear.com/7.x/avataaars/svg?seed=david', NOW() - INTERVAL '29 days', NOW() - INTERVAL '4 hours', NOW() - INTERVAL '30 days'),
    ('a1b2c3d4-e5f6-4789-abcd-999999999999', 'sofia.andersson@nordic.tech', 'Sofia Andersson', 'https://api.dicebear.com/7.x/avataaars/svg?seed=sofia', NOW() - INTERVAL '24 days', NOW() - INTERVAL '2 days', NOW() - INTERVAL '25 days'),
    ('a1b2c3d4-e5f6-4789-abcd-aaaaaaaaaaaa', 'ryan.ogrady@startup.ie', 'Ryan O''Grady', 'https://api.dicebear.com/7.x/avataaars/svg?seed=ryan', NOW() - INTERVAL '19 days', NOW() - INTERVAL '8 hours', NOW() - INTERVAL '20 days'),
    ('a1b2c3d4-e5f6-4789-abcd-bbbbbbbbbbbb', 'mei.zhang@enterprise.cn', 'Mei Zhang', 'https://api.dicebear.com/7.x/avataaars/svg?seed=mei', NOW() - INTERVAL '14 days', NOW() - INTERVAL '1 hour', NOW() - INTERVAL '15 days'),
    ('a1b2c3d4-e5f6-4789-abcd-cccccccccccc', 'lucas.fernandez@latam.io', 'Lucas Fernandez', NULL, NOW() - INTERVAL '9 days', NOW() - INTERVAL '16 hours', NOW() - INTERVAL '10 days'),
    ('a1b2c3d4-e5f6-4789-abcd-dddddddddddd', 'anna.kowalski@polish.dev', 'Anna Kowalski', 'https://api.dicebear.com/7.x/avataaars/svg?seed=anna', NOW() - INTERVAL '7 days', NOW() - INTERVAL '3 hours', NOW() - INTERVAL '8 days'),
    ('a1b2c3d4-e5f6-4789-abcd-eeeeeeeeeeee', 'tom.nguyen@saigon.tech', 'Tom Nguyen', 'https://api.dicebear.com/7.x/avataaars/svg?seed=tom', NOW() - INTERVAL '6 days', NOW() - INTERVAL '45 minutes', NOW() - INTERVAL '7 days'),
    ('a1b2c3d4-e5f6-4789-abcd-ffffffffffff', 'lisa.jackson@remote.work', 'Lisa Jackson', 'https://api.dicebear.com/7.x/avataaars/svg?seed=lisa', NOW() - INTERVAL '4 days', NOW() - INTERVAL '20 hours', NOW() - INTERVAL '5 days'),
    ('b1b2c3d4-e5f6-4789-abcd-111111111111', 'ahmed.hassan@cairo.dev', 'Ahmed Hassan', NULL, NULL, NULL, NOW() - INTERVAL '4 days'),
    ('b1b2c3d4-e5f6-4789-abcd-222222222222', 'nina.volkov@moscow.io', 'Nina Volkov', 'https://api.dicebear.com/7.x/avataaars/svg?seed=nina', NOW() - INTERVAL '2 days', NOW() - INTERVAL '5 hours', NOW() - INTERVAL '3 days'),
    ('b1b2c3d4-e5f6-4789-abcd-333333333333', 'chris.baker@london.agency', 'Chris Baker', 'https://api.dicebear.com/7.x/avataaars/svg?seed=chris', NOW() - INTERVAL '1 day', NOW() - INTERVAL '30 minutes', NOW() - INTERVAL '2 days'),
    ('b1b2c3d4-e5f6-4789-abcd-444444444444', 'yuki.tanaka@tokyo.tech', 'Yuki Tanaka', 'https://api.dicebear.com/7.x/avataaars/svg?seed=yuki', NOW() - INTERVAL '12 hours', NOW() - INTERVAL '2 hours', NOW() - INTERVAL '1 day'),
    ('b1b2c3d4-e5f6-4789-abcd-555555555555', 'fatima.ali@dubai.startup', 'Fatima Ali', NULL, NULL, NULL, NOW() - INTERVAL '6 hours');

-- Organizations (8 organizations with varied plans)
INSERT INTO organizations (id, name, slug, plan, logo_url, website, billing_email, metadata, created_at) VALUES
    ('c1c2c3c4-e5f6-4789-abcd-111111111111', 'Acme Corporation', 'acme-corp', 'enterprise', 'https://api.dicebear.com/7.x/identicon/svg?seed=acme', 'https://acme.example.com', 'billing@acme.example.com', '{"industry": "technology", "size": "500-1000", "region": "north-america"}', NOW() - INTERVAL '88 days'),
    ('c1c2c3c4-e5f6-4789-abcd-222222222222', 'Startup Labs', 'startup-labs', 'pro', 'https://api.dicebear.com/7.x/identicon/svg?seed=startuplabs', 'https://startuplabs.io', 'finance@startuplabs.io', '{"industry": "saas", "size": "10-50", "region": "europe"}', NOW() - INTERVAL '75 days'),
    ('c1c2c3c4-e5f6-4789-abcd-333333333333', 'DevHouse Agency', 'devhouse', 'pro', 'https://api.dicebear.com/7.x/identicon/svg?seed=devhouse', 'https://devhouse.io', NULL, '{"industry": "agency", "size": "50-100"}', NOW() - INTERVAL '60 days'),
    ('c1c2c3c4-e5f6-4789-abcd-444444444444', 'Nordic Tech Solutions', 'nordic-tech', 'starter', NULL, 'https://nordic-tech.se', 'accounts@nordic-tech.se', '{"industry": "consulting", "size": "10-50", "region": "europe"}', NOW() - INTERVAL '45 days'),
    ('c1c2c3c4-e5f6-4789-abcd-555555555555', 'Solo Developer', 'solo-dev', 'free', NULL, NULL, NULL, '{}', NOW() - INTERVAL '30 days'),
    ('c1c2c3c4-e5f6-4789-abcd-666666666666', 'Enterprise Global Inc', 'enterprise-global', 'enterprise', 'https://api.dicebear.com/7.x/identicon/svg?seed=enterprise', 'https://enterprise-global.com', 'ap@enterprise-global.com', '{"industry": "finance", "size": "1000+", "region": "global"}', NOW() - INTERVAL '20 days'),
    ('c1c2c3c4-e5f6-4789-abcd-777777777777', 'Fresh Startup', 'fresh-startup', 'starter', NULL, NULL, 'hello@freshstartup.co', '{"industry": "fintech", "size": "1-10"}', NOW() - INTERVAL '10 days'),
    ('c1c2c3c4-e5f6-4789-abcd-888888888888', 'Trial Company', 'trial-company', 'free', NULL, NULL, NULL, '{}', NOW() - INTERVAL '3 days');

-- Memberships
INSERT INTO memberships (user_id, organization_id, role, invited_by, joined_at) VALUES
    -- Acme Corporation (enterprise) - 6 members
    ('a1b2c3d4-e5f6-4789-abcd-111111111111', 'c1c2c3c4-e5f6-4789-abcd-111111111111', 'owner', NULL, NOW() - INTERVAL '88 days'),
    ('a1b2c3d4-e5f6-4789-abcd-222222222222', 'c1c2c3c4-e5f6-4789-abcd-111111111111', 'admin', 'a1b2c3d4-e5f6-4789-abcd-111111111111', NOW() - INTERVAL '85 days'),
    ('a1b2c3d4-e5f6-4789-abcd-333333333333', 'c1c2c3c4-e5f6-4789-abcd-111111111111', 'member', 'a1b2c3d4-e5f6-4789-abcd-111111111111', NOW() - INTERVAL '80 days'),
    ('a1b2c3d4-e5f6-4789-abcd-888888888888', 'c1c2c3c4-e5f6-4789-abcd-111111111111', 'member', 'a1b2c3d4-e5f6-4789-abcd-222222222222', NOW() - INTERVAL '30 days'),
    ('a1b2c3d4-e5f6-4789-abcd-bbbbbbbbbbbb', 'c1c2c3c4-e5f6-4789-abcd-111111111111', 'viewer', 'a1b2c3d4-e5f6-4789-abcd-222222222222', NOW() - INTERVAL '15 days'),
    ('b1b2c3d4-e5f6-4789-abcd-333333333333', 'c1c2c3c4-e5f6-4789-abcd-111111111111', 'member', 'a1b2c3d4-e5f6-4789-abcd-111111111111', NOW() - INTERVAL '2 days'),
    
    -- Startup Labs (pro) - 4 members
    ('a1b2c3d4-e5f6-4789-abcd-444444444444', 'c1c2c3c4-e5f6-4789-abcd-222222222222', 'owner', NULL, NOW() - INTERVAL '75 days'),
    ('a1b2c3d4-e5f6-4789-abcd-555555555555', 'c1c2c3c4-e5f6-4789-abcd-222222222222', 'admin', 'a1b2c3d4-e5f6-4789-abcd-444444444444', NOW() - INTERVAL '45 days'),
    ('a1b2c3d4-e5f6-4789-abcd-cccccccccccc', 'c1c2c3c4-e5f6-4789-abcd-222222222222', 'member', 'a1b2c3d4-e5f6-4789-abcd-444444444444', NOW() - INTERVAL '10 days'),
    ('b1b2c3d4-e5f6-4789-abcd-444444444444', 'c1c2c3c4-e5f6-4789-abcd-222222222222', 'member', 'a1b2c3d4-e5f6-4789-abcd-555555555555', NOW() - INTERVAL '1 day'),
    
    -- DevHouse Agency (pro) - 3 members
    ('a1b2c3d4-e5f6-4789-abcd-666666666666', 'c1c2c3c4-e5f6-4789-abcd-333333333333', 'owner', NULL, NOW() - INTERVAL '60 days'),
    ('a1b2c3d4-e5f6-4789-abcd-777777777777', 'c1c2c3c4-e5f6-4789-abcd-333333333333', 'admin', 'a1b2c3d4-e5f6-4789-abcd-666666666666', NOW() - INTERVAL '35 days'),
    ('a1b2c3d4-e5f6-4789-abcd-dddddddddddd', 'c1c2c3c4-e5f6-4789-abcd-333333333333', 'member', 'a1b2c3d4-e5f6-4789-abcd-666666666666', NOW() - INTERVAL '8 days'),
    
    -- Nordic Tech Solutions (starter) - 2 members
    ('a1b2c3d4-e5f6-4789-abcd-999999999999', 'c1c2c3c4-e5f6-4789-abcd-444444444444', 'owner', NULL, NOW() - INTERVAL '45 days'),
    ('a1b2c3d4-e5f6-4789-abcd-aaaaaaaaaaaa', 'c1c2c3c4-e5f6-4789-abcd-444444444444', 'member', 'a1b2c3d4-e5f6-4789-abcd-999999999999', NOW() - INTERVAL '20 days'),
    
    -- Solo Developer (free) - 1 member
    ('a1b2c3d4-e5f6-4789-abcd-eeeeeeeeeeee', 'c1c2c3c4-e5f6-4789-abcd-555555555555', 'owner', NULL, NOW() - INTERVAL '30 days'),
    
    -- Enterprise Global (enterprise) - 4 members
    ('a1b2c3d4-e5f6-4789-abcd-ffffffffffff', 'c1c2c3c4-e5f6-4789-abcd-666666666666', 'owner', NULL, NOW() - INTERVAL '20 days'),
    ('b1b2c3d4-e5f6-4789-abcd-111111111111', 'c1c2c3c4-e5f6-4789-abcd-666666666666', 'admin', 'a1b2c3d4-e5f6-4789-abcd-ffffffffffff', NOW() - INTERVAL '4 days'),
    ('b1b2c3d4-e5f6-4789-abcd-222222222222', 'c1c2c3c4-e5f6-4789-abcd-666666666666', 'member', 'a1b2c3d4-e5f6-4789-abcd-ffffffffffff', NOW() - INTERVAL '3 days'),
    ('b1b2c3d4-e5f6-4789-abcd-555555555555', 'c1c2c3c4-e5f6-4789-abcd-666666666666', 'viewer', 'b1b2c3d4-e5f6-4789-abcd-111111111111', NOW() - INTERVAL '6 hours'),
    
    -- Fresh Startup (starter) - 2 members  
    ('a1b2c3d4-e5f6-4789-abcd-cccccccccccc', 'c1c2c3c4-e5f6-4789-abcd-777777777777', 'owner', NULL, NOW() - INTERVAL '10 days'),
    ('a1b2c3d4-e5f6-4789-abcd-dddddddddddd', 'c1c2c3c4-e5f6-4789-abcd-777777777777', 'admin', 'a1b2c3d4-e5f6-4789-abcd-cccccccccccc', NOW() - INTERVAL '5 days'),
    
    -- Trial Company (free) - 1 member
    ('b1b2c3d4-e5f6-4789-abcd-444444444444', 'c1c2c3c4-e5f6-4789-abcd-888888888888', 'owner', NULL, NOW() - INTERVAL '3 days');

-- Projects (15 projects across organizations)
INSERT INTO projects (id, organization_id, name, description, status, settings, created_by, created_at) VALUES
    -- Acme Corporation projects
    ('d1d2d3d4-e5f6-4789-abcd-111111111111', 'c1c2c3c4-e5f6-4789-abcd-111111111111', 'Customer Portal', 'Main customer-facing web application', 'active', '{"environment": "production", "framework": "next.js"}', 'a1b2c3d4-e5f6-4789-abcd-111111111111', NOW() - INTERVAL '87 days'),
    ('d1d2d3d4-e5f6-4789-abcd-222222222222', 'c1c2c3c4-e5f6-4789-abcd-111111111111', 'Internal Dashboard', 'Admin tools and analytics', 'active', '{"environment": "production", "framework": "react"}', 'a1b2c3d4-e5f6-4789-abcd-222222222222', NOW() - INTERVAL '80 days'),
    ('d1d2d3d4-e5f6-4789-abcd-333333333333', 'c1c2c3c4-e5f6-4789-abcd-111111111111', 'Mobile App v2', 'React Native mobile application', 'active', '{"environment": "staging", "framework": "react-native"}', 'a1b2c3d4-e5f6-4789-abcd-333333333333', NOW() - INTERVAL '45 days'),
    ('d1d2d3d4-e5f6-4789-abcd-444444444444', 'c1c2c3c4-e5f6-4789-abcd-111111111111', 'Legacy API', 'Deprecated REST API (sunset Q2 2024)', 'paused', '{"environment": "production", "deprecated": true}', 'a1b2c3d4-e5f6-4789-abcd-111111111111', NOW() - INTERVAL '300 days'),
    ('d1d2d3d4-e5f6-4789-abcd-555555555555', 'c1c2c3c4-e5f6-4789-abcd-111111111111', 'Data Pipeline', NULL, 'archived', '{}', 'a1b2c3d4-e5f6-4789-abcd-222222222222', NOW() - INTERVAL '200 days'),
    
    -- Startup Labs projects
    ('d1d2d3d4-e5f6-4789-abcd-666666666666', 'c1c2c3c4-e5f6-4789-abcd-222222222222', 'SaaS Platform', 'Core product platform', 'active', '{"environment": "production"}', 'a1b2c3d4-e5f6-4789-abcd-444444444444', NOW() - INTERVAL '74 days'),
    ('d1d2d3d4-e5f6-4789-abcd-777777777777', 'c1c2c3c4-e5f6-4789-abcd-222222222222', 'Marketing Site', 'Public website and blog', 'active', '{"environment": "production", "cms": "contentful"}', 'a1b2c3d4-e5f6-4789-abcd-555555555555', NOW() - INTERVAL '50 days'),
    ('d1d2d3d4-e5f6-4789-abcd-888888888888', 'c1c2c3c4-e5f6-4789-abcd-222222222222', 'Analytics Service', 'Internal metrics and tracking', 'active', '{}', 'a1b2c3d4-e5f6-4789-abcd-444444444444', NOW() - INTERVAL '30 days'),
    
    -- DevHouse Agency projects
    ('d1d2d3d4-e5f6-4789-abcd-999999999999', 'c1c2c3c4-e5f6-4789-abcd-333333333333', 'Client: TechCorp', 'E-commerce platform build', 'active', '{"client": "techcorp", "deadline": "2024-06-30"}', 'a1b2c3d4-e5f6-4789-abcd-666666666666', NOW() - INTERVAL '55 days'),
    ('d1d2d3d4-e5f6-4789-abcd-aaaaaaaaaaaa', 'c1c2c3c4-e5f6-4789-abcd-333333333333', 'Client: HealthApp', 'Healthcare mobile app', 'active', '{"client": "healthapp"}', 'a1b2c3d4-e5f6-4789-abcd-777777777777', NOW() - INTERVAL '20 days'),
    ('d1d2d3d4-e5f6-4789-abcd-bbbbbbbbbbbb', 'c1c2c3c4-e5f6-4789-abcd-333333333333', 'Client: OldBank', 'Legacy system maintenance', 'archived', '{"client": "oldbank", "archived_reason": "contract_ended"}', 'a1b2c3d4-e5f6-4789-abcd-666666666666', NOW() - INTERVAL '180 days'),
    
    -- Nordic Tech Solutions
    ('d1d2d3d4-e5f6-4789-abcd-cccccccccccc', 'c1c2c3c4-e5f6-4789-abcd-444444444444', 'Consulting Tools', 'Internal tooling suite', 'active', '{}', 'a1b2c3d4-e5f6-4789-abcd-999999999999', NOW() - INTERVAL '40 days'),
    
    -- Solo Developer
    ('d1d2d3d4-e5f6-4789-abcd-dddddddddddd', 'c1c2c3c4-e5f6-4789-abcd-555555555555', 'Side Project', 'Personal SaaS experiment', 'active', '{"personal": true}', 'a1b2c3d4-e5f6-4789-abcd-eeeeeeeeeeee', NOW() - INTERVAL '28 days'),
    
    -- Enterprise Global
    ('d1d2d3d4-e5f6-4789-abcd-eeeeeeeeeeee', 'c1c2c3c4-e5f6-4789-abcd-666666666666', 'Trading Platform', 'Real-time trading system', 'active', '{"environment": "production", "compliance": "sox"}', 'a1b2c3d4-e5f6-4789-abcd-ffffffffffff', NOW() - INTERVAL '18 days'),
    ('d1d2d3d4-e5f6-4789-abcd-ffffffffffff', 'c1c2c3c4-e5f6-4789-abcd-666666666666', 'Risk Analytics', 'Risk assessment dashboard', 'active', '{"environment": "staging"}', 'b1b2c3d4-e5f6-4789-abcd-111111111111', NOW() - INTERVAL '3 days');

-- API Keys
INSERT INTO api_keys (id, organization_id, name, key_prefix, key_hash, scopes, last_used_at, expires_at, created_by, created_at, revoked_at) VALUES
    -- Acme Corporation
    ('e1e2e3e4-e5f6-4789-abcd-111111111111', 'c1c2c3c4-e5f6-4789-abcd-111111111111', 'Production API', 'pk_live_acm', 'sha256$a1b2c3d4e5f6g7h8i9j0...', ARRAY['read', 'write'], NOW() - INTERVAL '5 minutes', NOW() + INTERVAL '1 year', 'a1b2c3d4-e5f6-4789-abcd-111111111111', NOW() - INTERVAL '85 days', NULL),
    ('e1e2e3e4-e5f6-4789-abcd-222222222222', 'c1c2c3c4-e5f6-4789-abcd-111111111111', 'Staging API', 'pk_test_acm', 'sha256$b2c3d4e5f6g7h8i9j0k1...', ARRAY['read', 'write', 'delete'], NOW() - INTERVAL '2 hours', NULL, 'a1b2c3d4-e5f6-4789-abcd-222222222222', NOW() - INTERVAL '80 days', NULL),
    ('e1e2e3e4-e5f6-4789-abcd-333333333333', 'c1c2c3c4-e5f6-4789-abcd-111111111111', 'CI/CD Pipeline', 'pk_ci_acme', 'sha256$c3d4e5f6g7h8i9j0k1l2...', ARRAY['read'], NOW() - INTERVAL '1 day', NOW() + INTERVAL '90 days', 'a1b2c3d4-e5f6-4789-abcd-333333333333', NOW() - INTERVAL '60 days', NULL),
    ('e1e2e3e4-e5f6-4789-abcd-444444444444', 'c1c2c3c4-e5f6-4789-abcd-111111111111', 'Old Integration', 'pk_old_acme', 'sha256$d4e5f6g7h8i9j0k1l2m3...', ARRAY['read'], NOW() - INTERVAL '180 days', NOW() - INTERVAL '30 days', 'a1b2c3d4-e5f6-4789-abcd-111111111111', NOW() - INTERVAL '365 days', NOW() - INTERVAL '30 days'),
    
    -- Startup Labs
    ('e1e2e3e4-e5f6-4789-abcd-555555555555', 'c1c2c3c4-e5f6-4789-abcd-222222222222', 'Main API Key', 'pk_live_stl', 'sha256$e5f6g7h8i9j0k1l2m3n4...', ARRAY['read', 'write'], NOW() - INTERVAL '30 minutes', NULL, 'a1b2c3d4-e5f6-4789-abcd-444444444444', NOW() - INTERVAL '70 days', NULL),
    ('e1e2e3e4-e5f6-4789-abcd-666666666666', 'c1c2c3c4-e5f6-4789-abcd-222222222222', 'Webhook Service', 'pk_whk_stl', 'sha256$f6g7h8i9j0k1l2m3n4o5...', ARRAY['read'], NOW() - INTERVAL '4 hours', NULL, 'a1b2c3d4-e5f6-4789-abcd-555555555555', NOW() - INTERVAL '45 days', NULL),
    
    -- DevHouse Agency
    ('e1e2e3e4-e5f6-4789-abcd-777777777777', 'c1c2c3c4-e5f6-4789-abcd-333333333333', 'Client Projects', 'pk_live_dvh', 'sha256$g7h8i9j0k1l2m3n4o5p6...', ARRAY['read', 'write', 'delete'], NOW() - INTERVAL '12 hours', NULL, 'a1b2c3d4-e5f6-4789-abcd-666666666666', NOW() - INTERVAL '55 days', NULL),
    
    -- Enterprise Global
    ('e1e2e3e4-e5f6-4789-abcd-888888888888', 'c1c2c3c4-e5f6-4789-abcd-666666666666', 'Trading API', 'pk_live_ent', 'sha256$h8i9j0k1l2m3n4o5p6q7...', ARRAY['read', 'write', 'trade'], NOW() - INTERVAL '2 minutes', NULL, 'a1b2c3d4-e5f6-4789-abcd-ffffffffffff', NOW() - INTERVAL '15 days', NULL),
    ('e1e2e3e4-e5f6-4789-abcd-999999999999', 'c1c2c3c4-e5f6-4789-abcd-666666666666', 'Read-Only Analytics', 'pk_ro_ent', 'sha256$i9j0k1l2m3n4o5p6q7r8...', ARRAY['read'], NULL, NULL, 'b1b2c3d4-e5f6-4789-abcd-111111111111', NOW() - INTERVAL '3 days', NULL);

-- Subscriptions
INSERT INTO subscriptions (id, organization_id, plan, status, stripe_subscription_id, stripe_customer_id, current_period_start, current_period_end, cancel_at, canceled_at, trial_end, created_at) VALUES
    -- Acme Corporation - Enterprise (active)
    ('f1f2f3f4-e5f6-4789-abcd-111111111111', 'c1c2c3c4-e5f6-4789-abcd-111111111111', 'enterprise', 'active', 'sub_1NxYz123456789', 'cus_AcmeCorp001', NOW() - INTERVAL '28 days', NOW() + INTERVAL '2 days', NULL, NULL, NULL, NOW() - INTERVAL '88 days'),
    
    -- Startup Labs - Pro (active)
    ('f1f2f3f4-e5f6-4789-abcd-222222222222', 'c1c2c3c4-e5f6-4789-abcd-222222222222', 'pro', 'active', 'sub_2AbCd234567890', 'cus_StartupLabs01', NOW() - INTERVAL '15 days', NOW() + INTERVAL '15 days', NULL, NULL, NULL, NOW() - INTERVAL '75 days'),
    
    -- DevHouse Agency - Pro (past_due)
    ('f1f2f3f4-e5f6-4789-abcd-333333333333', 'c1c2c3c4-e5f6-4789-abcd-333333333333', 'pro', 'past_due', 'sub_3CdEf345678901', 'cus_DevHouse0001', NOW() - INTERVAL '35 days', NOW() - INTERVAL '5 days', NULL, NULL, NULL, NOW() - INTERVAL '60 days'),
    
    -- Nordic Tech Solutions - Starter (active)
    ('f1f2f3f4-e5f6-4789-abcd-444444444444', 'c1c2c3c4-e5f6-4789-abcd-444444444444', 'starter', 'active', 'sub_4EfGh456789012', 'cus_NordicTech01', NOW() - INTERVAL '10 days', NOW() + INTERVAL '20 days', NULL, NULL, NULL, NOW() - INTERVAL '45 days'),
    
    -- Enterprise Global - Enterprise (active)
    ('f1f2f3f4-e5f6-4789-abcd-555555555555', 'c1c2c3c4-e5f6-4789-abcd-666666666666', 'enterprise', 'active', 'sub_5GhIj567890123', 'cus_EntGlobal001', NOW() - INTERVAL '5 days', NOW() + INTERVAL '25 days', NULL, NULL, NULL, NOW() - INTERVAL '20 days'),
    
    -- Fresh Startup - Starter (trialing)
    ('f1f2f3f4-e5f6-4789-abcd-666666666666', 'c1c2c3c4-e5f6-4789-abcd-777777777777', 'starter', 'trialing', 'sub_6IjKl678901234', 'cus_FreshStart01', NOW() - INTERVAL '10 days', NOW() + INTERVAL '20 days', NULL, NULL, NOW() + INTERVAL '4 days', NOW() - INTERVAL '10 days'),
    
    -- Trial Company - Canceled subscription (for history)
    ('f1f2f3f4-e5f6-4789-abcd-777777777777', 'c1c2c3c4-e5f6-4789-abcd-888888888888', 'starter', 'canceled', 'sub_7KlMn789012345', 'cus_TrialCo00001', NOW() - INTERVAL '30 days', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days', NOW() - INTERVAL '5 days', NULL, NOW() - INTERVAL '30 days');

-- Invoices
INSERT INTO invoices (id, organization_id, subscription_id, stripe_invoice_id, amount_cents, currency, status, description, invoice_url, due_date, paid_at, created_at) VALUES
    -- Acme Corporation invoices
    ('11111111-e5f6-4789-abcd-111111111111', 'c1c2c3c4-e5f6-4789-abcd-111111111111', 'f1f2f3f4-e5f6-4789-abcd-111111111111', 'in_acme_001', 99900, 'USD', 'paid', 'Enterprise Plan - Monthly', 'https://invoice.stripe.com/i/acme_001', NOW() - INTERVAL '58 days', NOW() - INTERVAL '57 days', NOW() - INTERVAL '60 days'),
    ('11111111-e5f6-4789-abcd-222222222222', 'c1c2c3c4-e5f6-4789-abcd-111111111111', 'f1f2f3f4-e5f6-4789-abcd-111111111111', 'in_acme_002', 99900, 'USD', 'paid', 'Enterprise Plan - Monthly', 'https://invoice.stripe.com/i/acme_002', NOW() - INTERVAL '28 days', NOW() - INTERVAL '27 days', NOW() - INTERVAL '30 days'),
    ('11111111-e5f6-4789-abcd-333333333333', 'c1c2c3c4-e5f6-4789-abcd-111111111111', 'f1f2f3f4-e5f6-4789-abcd-111111111111', 'in_acme_003', 99900, 'USD', 'pending', 'Enterprise Plan - Monthly', 'https://invoice.stripe.com/i/acme_003', NOW() + INTERVAL '2 days', NULL, NOW()),
    
    -- Startup Labs invoices
    ('11111111-e5f6-4789-abcd-444444444444', 'c1c2c3c4-e5f6-4789-abcd-222222222222', 'f1f2f3f4-e5f6-4789-abcd-222222222222', 'in_stl_001', 4900, 'USD', 'paid', 'Pro Plan - Monthly', 'https://invoice.stripe.com/i/stl_001', NOW() - INTERVAL '45 days', NOW() - INTERVAL '45 days', NOW() - INTERVAL '45 days'),
    ('11111111-e5f6-4789-abcd-555555555555', 'c1c2c3c4-e5f6-4789-abcd-222222222222', 'f1f2f3f4-e5f6-4789-abcd-222222222222', 'in_stl_002', 4900, 'USD', 'paid', 'Pro Plan - Monthly', 'https://invoice.stripe.com/i/stl_002', NOW() - INTERVAL '15 days', NOW() - INTERVAL '14 days', NOW() - INTERVAL '15 days'),
    
    -- DevHouse Agency invoices (one failed)
    ('11111111-e5f6-4789-abcd-666666666666', 'c1c2c3c4-e5f6-4789-abcd-333333333333', 'f1f2f3f4-e5f6-4789-abcd-333333333333', 'in_dvh_001', 4900, 'USD', 'paid', 'Pro Plan - Monthly', 'https://invoice.stripe.com/i/dvh_001', NOW() - INTERVAL '35 days', NOW() - INTERVAL '34 days', NOW() - INTERVAL '35 days'),
    ('11111111-e5f6-4789-abcd-777777777777', 'c1c2c3c4-e5f6-4789-abcd-333333333333', 'f1f2f3f4-e5f6-4789-abcd-333333333333', 'in_dvh_002', 4900, 'USD', 'failed', 'Pro Plan - Monthly', 'https://invoice.stripe.com/i/dvh_002', NOW() - INTERVAL '5 days', NULL, NOW() - INTERVAL '5 days'),
    
    -- Nordic Tech Solutions
    ('11111111-e5f6-4789-abcd-888888888888', 'c1c2c3c4-e5f6-4789-abcd-444444444444', 'f1f2f3f4-e5f6-4789-abcd-444444444444', 'in_nts_001', 1900, 'USD', 'paid', 'Starter Plan - Monthly', 'https://invoice.stripe.com/i/nts_001', NOW() - INTERVAL '10 days', NOW() - INTERVAL '10 days', NOW() - INTERVAL '10 days'),
    
    -- Enterprise Global
    ('11111111-e5f6-4789-abcd-999999999999', 'c1c2c3c4-e5f6-4789-abcd-666666666666', 'f1f2f3f4-e5f6-4789-abcd-555555555555', 'in_ent_001', 99900, 'USD', 'paid', 'Enterprise Plan - Monthly', 'https://invoice.stripe.com/i/ent_001', NOW() - INTERVAL '5 days', NOW() - INTERVAL '4 days', NOW() - INTERVAL '5 days'),
    
    -- Refunded invoice example
    ('11111111-e5f6-4789-abcd-aaaaaaaaaaaa', 'c1c2c3c4-e5f6-4789-abcd-888888888888', 'f1f2f3f4-e5f6-4789-abcd-777777777777', 'in_trial_001', 1900, 'USD', 'refunded', 'Starter Plan - Monthly (Refunded)', 'https://invoice.stripe.com/i/trial_001', NOW() - INTERVAL '30 days', NOW() - INTERVAL '29 days', NOW() - INTERVAL '30 days');

-- Events (audit log)
INSERT INTO events (id, organization_id, user_id, type, resource_type, resource_id, payload, ip_address, user_agent, created_at) VALUES
    -- User signups
    ('22222222-e5f6-4789-abcd-111111111111', NULL, 'a1b2c3d4-e5f6-4789-abcd-111111111111', 'user.created', 'user', 'a1b2c3d4-e5f6-4789-abcd-111111111111', '{"email": "sarah.chen@gmail.com"}', '73.162.214.130', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)', NOW() - INTERVAL '90 days'),
    ('22222222-e5f6-4789-abcd-222222222222', NULL, 'b1b2c3d4-e5f6-4789-abcd-444444444444', 'user.created', 'user', 'b1b2c3d4-e5f6-4789-abcd-444444444444', '{"email": "yuki.tanaka@tokyo.tech"}', '103.5.140.219', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)', NOW() - INTERVAL '1 day'),
    ('22222222-e5f6-4789-abcd-333333333333', NULL, 'b1b2c3d4-e5f6-4789-abcd-555555555555', 'user.created', 'user', 'b1b2c3d4-e5f6-4789-abcd-555555555555', '{"email": "fatima.ali@dubai.startup"}', '94.56.229.180', 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0)', NOW() - INTERVAL '6 hours'),
    
    -- Organization creation
    ('22222222-e5f6-4789-abcd-444444444444', 'c1c2c3c4-e5f6-4789-abcd-111111111111', 'a1b2c3d4-e5f6-4789-abcd-111111111111', 'org.created', 'organization', 'c1c2c3c4-e5f6-4789-abcd-111111111111', '{"name": "Acme Corporation", "plan": "free"}', '73.162.214.130', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)', NOW() - INTERVAL '88 days'),
    ('22222222-e5f6-4789-abcd-555555555555', 'c1c2c3c4-e5f6-4789-abcd-888888888888', 'b1b2c3d4-e5f6-4789-abcd-444444444444', 'org.created', 'organization', 'c1c2c3c4-e5f6-4789-abcd-888888888888', '{"name": "Trial Company", "plan": "free"}', '103.5.140.219', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)', NOW() - INTERVAL '3 days'),
    
    -- Project creation
    ('22222222-e5f6-4789-abcd-666666666666', 'c1c2c3c4-e5f6-4789-abcd-111111111111', 'a1b2c3d4-e5f6-4789-abcd-111111111111', 'project.created', 'project', 'd1d2d3d4-e5f6-4789-abcd-111111111111', '{"name": "Customer Portal"}', '73.162.214.130', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)', NOW() - INTERVAL '87 days'),
    ('22222222-e5f6-4789-abcd-777777777777', 'c1c2c3c4-e5f6-4789-abcd-666666666666', 'b1b2c3d4-e5f6-4789-abcd-111111111111', 'project.created', 'project', 'd1d2d3d4-e5f6-4789-abcd-ffffffffffff', '{"name": "Risk Analytics"}', '185.45.12.89', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)', NOW() - INTERVAL '3 days'),
    
    -- Subscription events
    ('22222222-e5f6-4789-abcd-888888888888', 'c1c2c3c4-e5f6-4789-abcd-111111111111', 'a1b2c3d4-e5f6-4789-abcd-111111111111', 'subscription.started', 'subscription', 'f1f2f3f4-e5f6-4789-abcd-111111111111', '{"plan": "enterprise", "amount": 999}', '73.162.214.130', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)', NOW() - INTERVAL '88 days'),
    ('22222222-e5f6-4789-abcd-999999999999', 'c1c2c3c4-e5f6-4789-abcd-888888888888', 'b1b2c3d4-e5f6-4789-abcd-444444444444', 'subscription.canceled', 'subscription', 'f1f2f3f4-e5f6-4789-abcd-777777777777', '{"reason": "too_expensive", "feedback": "Will come back when we have more budget"}', '103.5.140.219', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)', NOW() - INTERVAL '5 days'),
    
    -- Invoice paid
    ('22222222-e5f6-4789-abcd-aaaaaaaaaaaa', 'c1c2c3c4-e5f6-4789-abcd-111111111111', NULL, 'invoice.paid', 'invoice', '11111111-e5f6-4789-abcd-222222222222', '{"amount": 999, "currency": "USD"}', NULL, NULL, NOW() - INTERVAL '27 days'),
    ('22222222-e5f6-4789-abcd-bbbbbbbbbbbb', 'c1c2c3c4-e5f6-4789-abcd-666666666666', NULL, 'invoice.paid', 'invoice', '11111111-e5f6-4789-abcd-999999999999', '{"amount": 999, "currency": "USD"}', NULL, NULL, NOW() - INTERVAL '4 days'),
    
    -- API key created
    ('22222222-e5f6-4789-abcd-cccccccccccc', 'c1c2c3c4-e5f6-4789-abcd-111111111111', 'a1b2c3d4-e5f6-4789-abcd-111111111111', 'api_key.created', 'api_key', 'e1e2e3e4-e5f6-4789-abcd-111111111111', '{"name": "Production API", "scopes": ["read", "write"]}', '73.162.214.130', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)', NOW() - INTERVAL '85 days'),
    ('22222222-e5f6-4789-abcd-dddddddddddd', 'c1c2c3c4-e5f6-4789-abcd-666666666666', 'a1b2c3d4-e5f6-4789-abcd-ffffffffffff', 'api_key.created', 'api_key', 'e1e2e3e4-e5f6-4789-abcd-888888888888', '{"name": "Trading API", "scopes": ["read", "write", "trade"]}', '185.45.12.89', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)', NOW() - INTERVAL '15 days'),
    
    -- Recent activity burst
    ('22222222-e5f6-4789-abcd-eeeeeeeeeeee', 'c1c2c3c4-e5f6-4789-abcd-111111111111', 'b1b2c3d4-e5f6-4789-abcd-333333333333', 'user.updated', 'user', 'b1b2c3d4-e5f6-4789-abcd-333333333333', '{"changes": ["avatar_url"]}', '88.120.45.67', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)', NOW() - INTERVAL '30 minutes');

-- Feature Flags
INSERT INTO feature_flags (id, name, description, enabled, rollout_percentage, allowed_organizations, metadata, created_at) VALUES
    ('33333333-e5f6-4789-abcd-111111111111', 'new_dashboard', 'Redesigned analytics dashboard with charts', true, 100, ARRAY[]::UUID[], '{"version": "2.0", "designer": "emma"}', NOW() - INTERVAL '60 days'),
    ('33333333-e5f6-4789-abcd-222222222222', 'ai_suggestions', 'AI-powered query suggestions in editor', true, 25, ARRAY['c1c2c3c4-e5f6-4789-abcd-111111111111', 'c1c2c3c4-e5f6-4789-abcd-666666666666']::UUID[], '{"model": "gpt-4", "beta": true}', NOW() - INTERVAL '30 days'),
    ('33333333-e5f6-4789-abcd-333333333333', 'dark_mode_v2', 'Updated dark mode color scheme', true, 50, ARRAY[]::UUID[], '{}', NOW() - INTERVAL '20 days'),
    ('33333333-e5f6-4789-abcd-444444444444', 'export_pdf', 'Export reports to PDF format', false, 0, ARRAY[]::UUID[], '{"status": "in_development", "eta": "2024-Q2"}', NOW() - INTERVAL '15 days'),
    ('33333333-e5f6-4789-abcd-555555555555', 'team_collaboration', 'Real-time collaboration features', true, 10, ARRAY['c1c2c3c4-e5f6-4789-abcd-111111111111']::UUID[], '{"websocket": true}', NOW() - INTERVAL '10 days'),
    ('33333333-e5f6-4789-abcd-666666666666', 'sso_okta', 'Okta SSO integration', false, 0, ARRAY['c1c2c3c4-e5f6-4789-abcd-666666666666']::UUID[], '{"enterprise_only": true}', NOW() - INTERVAL '5 days'),
    ('33333333-e5f6-4789-abcd-777777777777', 'billing_v2', 'New billing system with usage-based pricing', false, 0, ARRAY[]::UUID[], '{"migration_required": true}', NOW() - INTERVAL '2 days');

-- ============================================================================
-- HELPER VIEWS (optional but nice for demos)
-- ============================================================================

-- Organization summary view
CREATE VIEW organization_summary AS
SELECT 
    o.id,
    o.name,
    o.slug,
    o.plan,
    COUNT(DISTINCT m.user_id) as member_count,
    COUNT(DISTINCT p.id) as project_count,
    s.status as subscription_status,
    o.created_at
FROM organizations o
LEFT JOIN memberships m ON o.id = m.organization_id
LEFT JOIN projects p ON o.id = p.organization_id AND p.status = 'active'
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
-- Enjoy! 🚀
-- ============================================================================