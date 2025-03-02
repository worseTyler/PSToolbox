﻿using Dropbox.Api;
using Dropbox.Api.Files;
using System;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Management.Automation;
using System.Threading.Tasks;

namespace IntelliTect.PSDropbin
{
    [Cmdlet(VerbsCommon.Copy, Noun, SupportsShouldProcess = true)]
    public class CopyLocalToDropbox : PSCmdlet
    {
        private const string Noun = "LocalToDropbox";

        [Parameter(
                Position = 0,
                Mandatory = true,
                ValueFromPipeline = true,
                ValueFromPipelineByPropertyName = true)
        ]
        [ValidateNotNullOrEmpty]
        public string Path { get; set; }

        [Parameter(
                Position = 1,
                Mandatory = true,
                ValueFromPipeline = true,
                ValueFromPipelineByPropertyName = true)
        ]
        [ValidateNotNullOrEmpty]
        public string[] Destination { get; set; }

        protected override void ProcessRecord()
        {
            ProviderInfo dropboxProvider;
            string source = GetUnresolvedProviderPathFromPSPath(Path);
            string destination = GetResolvedProviderPathFromPSPath(Destination[0], out dropboxProvider).First();

            DropboxDriveInfo primaryDrive = dropboxProvider.Drives.Cast<DropboxDriveInfo>().First();

            if (ShouldProcess(source, "Copy-Item"))
            {
                destination = DropboxFileHelper.NormalizePath(destination);

                try
                {
                    if (primaryDrive.Client.Files.GetMetadataAsync(destination).Result.IsFolder)
                    {
                        destination += "/" + System.IO.Path.GetFileName(source);
                    }
                }
                catch (Exception)
                {
                    // ignored: file does not exist
                }

                if (Directory.Exists(source))
                {
                    string[] files = Directory.GetFiles(source, "*", SearchOption.AllDirectories);

                    foreach (string file in files)
                    {
                        UploadFile(file, destination + "/" + file.Remove(0, source.Length), primaryDrive);
                    }
                }
                else
                {
                    UploadFile(source, destination, primaryDrive);
                }
            }
        }

        private static void UploadFile(string source, string destination, DropboxDriveInfo drive)
        {
            using (FileStream stream = File.Open(source, FileMode.Open))
            {
                Debug.Assert(stream != null, "stream != null");

                string path = destination.Replace("\\", "/");
                CommitInfo info = new CommitInfo(path, WriteMode.Add.Instance, true);

                var metaData = drive.Client.Files.UploadAsync(info, stream).Result;
            }
        }
    }
}