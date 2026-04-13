Help with database and code migrations — schema changes, data transforms, dependency upgrades.

Migration: $ARGUMENTS (describe what's changing)

## Database Migrations

### 1. Plan the Schema Change
- **What's changing**: New table/column? Modified? Dropping?
- **Data type and constraints**: NOT NULL? Default? Foreign key? Index?
- **Existing data**: Need backfilling?
- **Reversibility**: Can this be rolled back?

### 2. Create the Migration
Detect the migration tool:
- **Alembic**: `alembic revision --autogenerate -m "description"`
- **Django**: `python manage.py makemigrations`
- **Prisma**: `npx prisma migrate dev --name description`
- **Knex**: `npx knex migrate:make description`
- **Rails**: `rails generate migration description`
- **Raw SQL**: Write migration script manually

### 3. Review the Migration
- Check `upgrade` does what you expect
- Check `downgrade` properly reverses it
- For NOT NULL on existing tables: add with default first, backfill, then optionally remove default

### 4. Test
- Back up the database first
- Run the migration
- Run the test suite
- Verify data integrity

## Library/Dependency Upgrades

### 1. Research
- Current version → target version
- Read changelog for breaking changes
- Check peer dependency impacts

### 2. Update
- Edit the dependency file
- Install: `pip install -r requirements.txt` / `npm install` / etc.

### 3. Find Affected Code
Search for imports from the upgraded library. Check each against changelog.

### 4. Test Everything
Run the full test suite + build.

## Safety Rules
- Always back up before schema changes
- One migration per logical change
- Write working rollback/downgrade code
- Test on a copy first
- Never drop tables/columns without confirming data isn't needed
