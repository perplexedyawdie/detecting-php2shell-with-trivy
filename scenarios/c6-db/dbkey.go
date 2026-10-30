// dbkey reads or deletes one key inside nested bbolt buckets (e.g. trivy.db).
//
//	dbkey get <db> <bucket>... <key>
//	dbkey del <db> <bucket>... <key>
package main

import (
	"fmt"
	"os"

	bolt "go.etcd.io/bbolt"
)

func main() {
	if len(os.Args) < 5 || (os.Args[1] != "get" && os.Args[1] != "del") {
		fmt.Fprintln(os.Stderr, "usage: dbkey get|del <db> <bucket>... <key>")
		os.Exit(2)
	}
	cmd, path, buckets, key := os.Args[1], os.Args[2], os.Args[3:len(os.Args)-1], os.Args[len(os.Args)-1]

	db, err := bolt.Open(path, 0o600, &bolt.Options{ReadOnly: cmd == "get"})
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	defer db.Close()

	walk := func(tx *bolt.Tx) *bolt.Bucket {
		b := tx.Bucket([]byte(buckets[0]))
		for _, name := range buckets[1:] {
			if b == nil {
				return nil
			}
			b = b.Bucket([]byte(name))
		}
		return b
	}

	if cmd == "get" {
		err = db.View(func(tx *bolt.Tx) error {
			if b := walk(tx); b != nil {
				if v := b.Get([]byte(key)); v != nil {
					fmt.Println(string(v))
					return nil
				}
			}
			fmt.Println("not found")
			return nil
		})
	} else {
		err = db.Update(func(tx *bolt.Tx) error {
			b := walk(tx)
			if b == nil || b.Get([]byte(key)) == nil {
				return fmt.Errorf("%s not found", key)
			}
			return b.Delete([]byte(key))
		})
	}
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
