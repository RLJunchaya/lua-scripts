import path from 'path'

import { getInput } from '@actions/core'
import fs from 'fs-extra'

import { bundleFile } from './bundle'

const IS_DEV_ENVIRONMENT = process.env.NODE_ENV === 'development'
const sourcePath = IS_DEV_ENVIRONMENT
    ? path.join('..', '..', '..', 'src')
    : path.join(...getInput('source', { required: true }).split('/'))

const outputPath = IS_DEV_ENVIRONMENT
    ? path.join('..', '..', '..', 'dist')
    : path.join(...getInput('output', { required: true }).split('/'))

/*
   remove old bundled files (if they exist)
    */

fs.ensureDirSync(outputPath)
fs.readdirSync(outputPath).forEach(fileName => fs.removeSync(fileName))

/*
   bundle and save source files
    */

const sourceFiles = fs.readdirSync(sourcePath).filter(fileName => fileName.endsWith('.lua'))

sourceFiles.forEach(file => {
    if (file.startsWith('personal')) return
    const bundledFile = bundleFile(file, sourcePath)
    fs.writeFileSync(path.join(outputPath, file), bundledFile)
})
