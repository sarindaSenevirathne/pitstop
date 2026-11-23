# Database migrations

`../database-pitstop.sql` builds the database as it was before this folder existed. Every change since is a numbered file here, applied once, in order.

| File | What it does |
|---|---|
| `001_products_topics_journeys.sql` | Adds `product`, `topic`, `journey_stage_template` (with the 10 stages), `journey_stage` and `journey_stage_item`, and the nullable `product_id` and `topic_id` columns on `content` |
| `001_down.sql` | Rollback for 001 (and 002): removes exactly what they added |
| `002_backfill_products_topics.sql` | One-off: gives existing content its product and topic from the page (by ID) it sits on. Fill in its steps 1 and 3 before running |

## Where they run

1. **Local MySQL 8** first, on a copy of the schema.
2. **Staging** next, to build and test the new screens against. Staging is shared with the legacy app's staging, so tell the team before applying, and keep the `_down` file ready.
3. **Production** only when the feature is final: ask the database owner to run the agreed files, in order, after a backup and outside working hours. Production is never changed directly from a developer machine.

## Rules

- **Only add.** A migration doesn't drop, rename or change what the current pages, sections and content screens read, so the current app keeps working.
- **Never edit a file that has been applied** to staging or production. Fix it with the next number.
- **Name** files `NNN_what_it_does.sql`, three digits, with no gaps.
- **Try it on a local MySQL 8 copy first,** then on staging, then on production. Staging is shared, so tell the team before applying there.
- **Record** each file applied in the PR that adds it and in the release notes, with the date and the environment.

## Applying one

```bash
mysql --ssl-mode=REQUIRED -h <host> -u <user> -p <database> < 001_products_topics_journeys.sql
```
